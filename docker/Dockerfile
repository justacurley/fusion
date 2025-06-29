FROM ironmansoftware/universal:latest
LABEL description="Universal - The ultimate platform for building web-based IT Tools" 

# Build argument for the Application Insights connection string
ARG APPLICATIONINSIGHTS_CONNECTION_STRING

EXPOSE 5000
VOLUME ["/home/data"]
ENV Data__RepositoryPath /home/data/Repository
ENV Data__ConnectionString Data Source=/home/data/database.db
ENV UniversalDashboard__AssetsFolder /home/data/UniversalDashboard 
ENV Logging__Path /home/data/logs/log.txt
ENV APPLICATIONINSIGHTS_CONNECTION_STRING InstrumentationKey=9c17d60c-44b9-4fcc-abf1-2f1fe142f9a1;IngestionEndpoint=https://westus2-2.in.applicationinsights.azure.com/;LiveEndpoint=https://westus2.livediagnostics.monitor.azure.com/;ApplicationId=e8d9d6b9-dfa4-4aad-9ff8-6a486da55d41
ENTRYPOINT ["./Universal/Universal.Server"]