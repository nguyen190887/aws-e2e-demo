$functionName = "Lambda.CreateImageInfo"
cd $functionName
dotnet publish --configuration Release
Compress-Archive .\bin\Release\netcoreapp2.0\publish\* "..\$functionName.zip" -Force
cd ..
terraform apply -auto-approve