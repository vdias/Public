# Define the Real-Debrid API endpoints
$baseURL = "https://api.real-debrid.com/rest/1.0"
$addTorrentEndpoint = "$baseURL/torrents/addTorrent"
$listTorrentsEndpoint = "$baseURL/torrents"
$selectFilesEndpoint = "$baseURL/torrents/selectFiles/"

# Your Real-Debrid API Key
$apiKey = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Folder containing torrent files
$torrentsFolder = "C:\Apps\AddToRealDebrid\torrents"

# Function to add a torrent file to Real-Debrid
function AddTorrentToRealDebrid($torrentFilePath) {
    # Prepare headers
    $headers = @{
        "Authorization" = "Bearer $apiKey"
    }

    # Read the torrent file content as byte array
    $torrentContent = [System.IO.File]::ReadAllBytes($torrentFilePath)

    # Send PUT request to Real-Debrid API to add the torrent
    try {
        $response = Invoke-RestMethod -Uri $addTorrentEndpoint -Method Put -Headers $headers -ContentType "application/octet-stream" -Body $torrentContent
        Write-Host "Torrent added successfully: $($response.filename)"
        return $response
    } catch {
        Write-Host "Failed to add torrent: $_"
        return $null
    }
}

# Function to get torrent details, including the list of files
function GetTorrentDetails($torrentId) {
    # Prepare headers
    $headers = @{
        "Authorization" = "Bearer $apiKey"
    }

    # Send GET request to Real-Debrid API to get torrent details
    try {
        $response = Invoke-RestMethod -Uri ($listTorrentsEndpoint + "/info/$torrentId") -Method Get -Headers $headers
        Write-Host "Torrent details for torrent ID: $torrentId"
        Write-Host "Response: $response"
        if ($response.torrent.files) {
            Write-Host "Files found in torrent:"
            foreach ($file in $response.torrent.files) {
                Write-Host "File: $($file.filename)"
            }
        } else {
            Write-Host "No files found in torrent."
        }
    } catch {
        Write-Host "Failed to get torrent information for torrent $($torrentId): $_"
    }
}


# Function to select all files for a torrent
function SelectAllFilesInTorrent($torrentId) {
    # Prepare headers
    $headers = @{
        "Authorization" = "Bearer $apiKey"
    }

    # Prepare payload to select all files
    $payload = @{
        "files" = "*"
    }

    # Send POST request to Real-Debrid API to select all files in the torrent
    try {
        $response = Invoke-RestMethod -Uri ($selectFilesEndpoint + "/$torrentId") -Method Post -Headers $headers -ContentType "application/json" -Body ($payload | ConvertTo-Json)
        Write-Host "All files selected for torrent: $torrentId"
        return $true
    } catch {
        Write-Host "Failed to select all files for torrent $($torrentId): $($_.Exception.Message)"
        if ($_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq "BadRequest") {
            $responseContent = $_.Exception.Response.Content
            Write-Host "Response content: $responseContent"
        }
        return $false
    }
}

# Function to add a torrent file to Real-Debrid and select all files
function AddTorrentAndSelectAllFiles($torrentFilePath) {
    # Add torrent file to Real-Debrid
    $torrentInfo = AddTorrentToRealDebrid $torrentFilePath
    if ($torrentInfo) {
        $torrentId = $torrentInfo.id
        Write-Host "Torrent added successfully: $($torrentInfo.filename)"
        
        # Get torrent details (list of files)
        GetTorrentDetails $torrentId
        
        # Select all files within the torrent
        SelectAllFilesInTorrent $torrentId
    }
}

# Get all torrent files in the folder
$torrentFiles = Get-ChildItem -Path $torrentsFolder -Filter *.torrent

# Add each torrent file to Real-Debrid and select all files
foreach ($torrentFile in $torrentFiles) {
    AddTorrentAndSelectAllFiles $torrentFile.FullName
}
