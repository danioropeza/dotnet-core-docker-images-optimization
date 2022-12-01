FROM mcr.microsoft.com/dotnet/sdk:6.0 AS dev-base
WORKDIR /src

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y

RUN apt-get install -y jq

FROM dev-base as build
USER root

COPY . .
RUN dotnet build YourApplication.API.sln -c Release -o /app


FROM build AS publish
RUN dotnet publish "YourApplication.API/YourApplication.API.csproj" -c Release -o /app \
    --runtime alpine-x64 \
    --self-contained true \
    /p:PublishTrimmed=true \
    /p:PublishSingleFile=true

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0-alpine AS final
RUN sed -i '1i openssl_conf = default_conf' /etc/ssl/openssl.cnf && echo -e "\n[ default_conf ]\nssl_conf = ssl_sect\n[ssl_sect]\nsystem_default = system_default_sect\n[system_default_sect]\nMinProtocol = TLSv1\nCipherString = DEFAULT:@SECLEVEL=1" >> /etc/ssl/openssl.cnf

WORKDIR /app
EXPOSE 80

COPY --from=publish /app .
ENTRYPOINT ["./YourApplication.API"]