FROM ubuntu:noble

LABEL maintainer="tsktp"

ENV WINEPREFIX=/root/.wine64
ENV WINEARCH=win64
ENV DISPLAY=:0

RUN dpkg --add-architecture i386

RUN apt-get update -qq && \
	apt-get install -qq curl wget git xvfb winbind wine64 wine32:i386 cabextract bzip2 && \
	apt-get clean -qq all
	
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
	chmod +x winetricks && \
	mv winetricks /usr/bin/
	
RUN wget https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.102/dotnet-sdk-10.0.102-win-x64.exe && \
	DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" wine dotnet-sdk-10.0.102-win-x64.exe /install /quiet && \
	rm dotnet-sdk-10.0.102-win-x64.exe

RUN wget https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.102/dotnet-sdk-10.0.102-win-x86.exe && \
	DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" wine dotnet-sdk-10.0.102-win-x86.exe /install /quiet && \
	rm dotnet-sdk-10.0.102-win-x86.exe
	
RUN wget --no-check-certificate https://symantec.tbs-certificats.com/vsign-universal-root.crt && \
	mkdir -p /usr/local/share/ca-certificates/extra && \
	cp vsign-universal-root.crt /usr/local/share/ca-certificates/extra/vsign-universal-root.crt && \
	update-ca-certificates && \
	rm vsign-universal-root.crt

RUN DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" winetricks -q powershell cmake mingw 7zip cabinet

RUN DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" winetricks -q d3dxof dxdiag dxvk dxvk_async dxvk_nvapi

# RUN DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" winetricks -q cmd crypt32 dotnet10 d3drm d3dx9 d3dx10 dxdiagn vkd3d

RUN wget https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.tar.bz2 && \
	mkdir /root/.wine64/drive_c/Git && \
	tar xjvf Git-2.52.0-64-bit.tar.bz2 -C /root/.wine64/drive_c/Git && \
	rm Git-2.52.0-64-bit.tar.bz2 && \
	ln -s /root/.wine64/drive_c/Git/bin/git.exe /root/.wine64/drive_c/MinGW/bin/git.exe

WORKDIR /root

RUN mkdir -p /root/sbox && \
	git clone --depth 1 https://github.com/Facepunch/sbox-public.git /root/sbox
	
WORKDIR /root/sbox

RUN DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build --config Developer && \
	DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build-shaders && \
	DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build-content
