# Disable the progress bar, makes the program run substantially faster
$ProgressPreference = "SilentlyContinue"

# Recursively search for all data files present on the given device
function QueryDirectory {
    param ($path, $count, $userDate, $userDevice)

    Write-Host "Path: $path"

    # Create the target location to search
    $uri = "192.168.50.10/" + $path
    
    # Query all files present at the target uri
    $response = Invoke-WebRequest -UseBasicParsing -Uri $uri

    $count += 1

    # Search through all queried items looking for directories and files
    foreach($link in $response.Links) {

        # If the item is a directory, and not the api directory, recursively call the function
        if ($link.innerText -match '/$' -And $link.innerText -ne "api/" -And $link.innerText -ne "/" -And $link.innerText -notmatch "\/[a-z,A-Z]") {

            $deviceDir = $userDevice + "Logs/"
            if ($count -eq 1 -And $deviceDir -ne $link.innerText -And $userDevice -ne $null) {
                Write-Host "Data is for diferent device. Skipping dir: "$link.innerText
                continue
            } 

            $newPath = $path + $link.innerText

            # Call function with updated function
            QueryDirectory $newPath $count $userDate $userDevice
        }
        elseif ($link.href -match '/$' -And $link.href -ne "api/" -And $link.href -ne "/" -And $link.href -notmatch "\/[a-z,A-Z]") {
            $discovered = $link.href

            $newPath = $path + $discovered

            $deviceDir = $userDevice + "Logs/"
            Write-Host "Desired dir: $deviceDir"
            if ($count -eq 1 -And $deviceDir -ne $link.href -And $userDevice -ne $null) {
                Write-Host "Data is for diferent device. Skipping dir: "$link.href
                continue
            }

            $newPath = $path + $link.href

            # Call function with updated function
            QueryDirectory $newPath $count $userDate $userDevice
        }
        # If the target is a file, download it
        elseif ($link.innerText -match '.csv$') {
        }
        elseif ($link.href -match '.csv$') {

            $date = $link.href.Substring($link.href.IndexOf("_") + 1, $link.href.lastIndexOf('.') - $link.href.IndexOf("_") - 1)

            $parseddate = userInput $date

            Write-Host "Parseddate: "$parseddate
            Write-Host "userDate: "$userDate

            if($userDate -eq $null -Or $parseddate -ge $userDate) {
                #keep
                Write-Host "Keeping "$link.href
                # Create string that contains the location of the target file on the device
                $target = $uri + $link.href
                # Create destination location to download the file at
                $dest = $path + $link.href

                # If the destination directory does not exist, create it
                    if (!(Test-Path -Path $path)) {
                    New-Item -ItemType "directory" -Path $path
                     }       

                # Log progress
                Write-Host "Download "$target" to "$dest
                # Perform the file download
                Invoke-WebRequest -Uri $target -OutFile $dest
                  } else {
                #not
                Write-Host "Ignoring "$link.href
            }
        }
    }
}

function userInput{
    param($userDate)

    $userYear = $userDate.Substring(0,4)
    $userMonth = $userDate.Substring(5,2)
    $userDay= $userDate.Substring(8,2)

    $userDate = (Get-Date -Year $userYear -Month $userMonth -Day $userDay -Hour 0 -Minute 0 -Second 0 -Millisecond 0)

    return $userDate
}

$inputDateString = $args[0]
$userDevice = $args[1]

if ($inputDateString -eq $null){

} else {

$userDate = userInput $inputDateString 

Write-Host $userDate

}

# Start the download process
  QueryDirectory "" 0 $userDate $userDevice

