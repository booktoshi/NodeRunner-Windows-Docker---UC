# Use the official Windows Server Core as a base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set environment variables for Powershell
SHELL ["powershell", "-Command"]

# Update and install necessary packages
RUN Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vs_buildtools.exe -OutFile vs_buildtools.exe ; \
    Start-Process -FilePath .\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -NoNewWindow -Wait ; \
    Remove-Item -Force vs_buildtools.exe

# Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install necessary tools and libraries using Chocolatey
RUN choco install -y git curl nano python3

# Download and install Dogecoin binaries
RUN Invoke-WebRequest -Uri https://github.com/dogecoin/dogecoin/releases/download/v1.14.7/dogecoin-1.14.7-win64.zip -OutFile dogecoin.zip ; \
    Expand-Archive -Path dogecoin.zip -DestinationPath C:\dogecoin ; \
    Remove-Item -Force dogecoin.zip

# Add Dogecoin binaries to PATH
RUN $env:Path += ';C:\dogecoin\dogecoin-1.14.7\bin'

# Start the Dogecoin node and run for 60 seconds, then stop it
RUN Start-Process -FilePath 'dogecoind.exe' -ArgumentList '-daemon' -NoNewWindow ; \
    Start-Sleep -Seconds 60 ; \
    Start-Process -FilePath 'dogecoin-cli.exe' -ArgumentList 'stop' -NoNewWindow

# Create and configure dogecoin.conf
RUN New-Item -Path 'C:\Users\ContainerAdministrator\AppData\Roaming\Dogecoin' -ItemType Directory -Force ; \
    Set-Content -Path 'C:\Users\ContainerAdministrator\AppData\Roaming\Dogecoin\dogecoin.conf' -Value "rpcuser=user`nrpcpassword=pass`nrpcallowip=127.0.0.1`nmaxconnections=50`nrpcport=22555`nport=22556`nlisten=1`nserver=1`ndaemon=1"

# Install NVM
RUN Invoke-WebRequest -Uri https://github.com/coreybutler/nvm-windows/releases/download/1.1.9/nvm-setup.exe -OutFile nvm-setup.exe ; \
    Start-Process -FilePath .\nvm-setup.exe -ArgumentList '/S' -NoNewWindow -Wait ; \
    Remove-Item -Force nvm-setup.exe

# Install Node.js using NVM
RUN & "C:\Program Files\nvm\nvm.exe" install stable ; \
    & "C:\Program Files\nvm\nvm.exe" use stable

# Clone Doginals repository
RUN git clone https://github.com/booktoshi/doginals.git C:\doginals

# Set the working directory
WORKDIR C:\doginals

# Install npm packages
RUN npm install

# Create and save .env file
RUN Set-Content -Path '.env' -Value "NODE_RPC_URL=http://127.0.0.1:22555`nNODE_RPC_USER=user`nNODE_RPC_PASS=pass`nTESTNET=false`nFEE_PER_KB=30000000"

# Create a new wallet
RUN node . wallet new

# Add a script to manage the state and timer
COPY manage.ps1 C:\manage.ps1
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    ./manage.ps1

# Start the state management script
CMD ["powershell.exe", "C:\\manage.ps1"]
