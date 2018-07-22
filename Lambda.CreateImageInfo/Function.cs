using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;
using Amazon.Lambda.Core;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.Json.JsonSerializer))]

namespace Lambda.CreateImageInfo
{
    public class Function
    {
        private AmazonDynamoDBClient _dynamoDbClient;
        private const string TableName = "ImageInfo";

        public Function()
        {
            _dynamoDbClient = new AmazonDynamoDBClient();
        }

        public Function(AmazonDynamoDBClient dynamoDbClient)
        {
            _dynamoDbClient = dynamoDbClient;
        }

        /// <summary>
        /// Function handler.
        /// </summary>
        /// <param name="input"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        public async Task FunctionHandler(ImageInfo imageInfo, ILambdaContext context)
        {
            Console.WriteLine("ObjectKey: " + imageInfo.ObjectKey);

            Table table = null;
            if (!Table.TryLoadTable(_dynamoDbClient, TableName, out table))
            {
                table = await CreateTable(TableName);
            }

            if (table == null)
            {
                Console.WriteLine("Error: Cannot create table");
                return;
            }

            try
            {
                await table.PutItemAsync(ObjectToDocument(imageInfo));
                Console.WriteLine("\nPutItem succeeded.\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("\n Error: Table.PutItem failed because: " + ex.ToString());
            }
        }

        private static Document ObjectToDocument(ImageInfo imageInfo)
        {
            return new Document()
            {
                {"ObjectKey", imageInfo.ObjectKey },
                {"User", imageInfo.User },
                {"FileName", imageInfo.FileName ?? string.Empty },
                {"ETag", imageInfo.ETag ?? string.Empty },
                {"CreatedDate", imageInfo.CreatedDate.ToString("yyyy-MM-ddTHH:mm:ssZ") },
                {"UpdatedDate", imageInfo.UpdatedDate.ToString("yyyy-MM-ddTHH:mm:ssZ") }
            };
        }

        // TODO: move this to terraform
        private async Task<Table> CreateTable(string tableName)
        {
            // Build a 'CreateTableRequest' for the new table
            CreateTableRequest createRequest = new CreateTableRequest
            {
                TableName = tableName,
                AttributeDefinitions = new List<AttributeDefinition>()
                {
                    new AttributeDefinition
                    {
                        AttributeName = "ObjectKey",
                        AttributeType = "S"
                    },
                    new AttributeDefinition
                    {
                        AttributeName = "UpdatedDate",
                        AttributeType = "S"
                    }
                },
                KeySchema = new List<KeySchemaElement>()
                {
                    new KeySchemaElement
                    {
                        AttributeName = "ObjectKey",
                        KeyType = "HASH"
                    },
                    new KeySchemaElement
                    {
                        AttributeName = "UpdatedDate",
                        KeyType = "RANGE"
                    }
                },
            };

            createRequest.ProvisionedThroughput = new ProvisionedThroughput(1, 1);

            try
            {
                CreateTableResponse createResponse = await _dynamoDbClient.CreateTableAsync(createRequest);
                Console.WriteLine("\n\n Created table successfully!\n    Status of the new table: '{0}'", createResponse.TableDescription.TableStatus);
                Thread.Sleep(3000); // wait some times for creating table - TODO: should have better option
                return Table.LoadTable(_dynamoDbClient, TableName);
            }
            catch (Exception ex)
            {
                Console.WriteLine("\n Error: failed to create the new table; " + ex.Message);
            }
            return null;
        }
    }

    public class ImageInfo
    {
        public string User { get; set; }
        public string FileName { get; set; }
        public string ObjectKey { get; set; }
        public string ThumbnailKey { get; set; }
        public string ETag { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime UpdatedDate { get; set; }
    }
}
