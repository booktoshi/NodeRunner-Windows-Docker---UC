# Start the Dogecoin node
Start-Process -FilePath "C:\dogecoin\dogecoin-1.14.7\bin\dogecoind.exe" -ArgumentList "-daemon" -NoNewWindow

# Wait for the node to start
Start-Sleep -Seconds 10

# Check the node status
& "C:\dogecoin\dogecoin-1.14.7\bin\dogecoin-cli.exe" getblockchaininfo

# Keep the script running
while ($true) {
    Start-Sleep -Seconds 60
    Write-Output "Dogecoin node is running..."
}
