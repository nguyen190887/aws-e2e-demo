const AWS = require('aws-sdk');
const im = require('imagemagick');
const fs = require('fs');

var s3 = new AWS.S3({
    "region": "us-west-2"
});

var handleUpload = (err, data) => {
     if (err) {
         console.error(err);
     } else {
         console.info(`Resize image successfully - Data: ${JSON.stringify(data, null, 2)}`);
     }
 };

var resizeAndUpload = (err, data, info) => {
     if (err) {
        console.error(err);
     } else {
        im.resize({
            srcData: data.Body,
            width: 200
        }, (err, stdout) => {
            s3.putObject({
                "Bucket": info.bucketName,
                "Key": `thumbs/${info.fileName}`,
                "Body": new Buffer(stdout, 'binary')
            }, handleUpload);
        });
     }
 };

exports.handler = (event, context, callback) => {
    let s3Object = event.Records[0].s3;
    const {bucket: {name: bucketName}, object: {key: objectKey}} = s3Object;
    const fileName = objectKey.replace('images/', '');
    let tempFile = `./temp_${fileName}`;

    s3.getObject({
        "Bucket": bucketName,
        "Key": objectKey
    }, (err, data) => resizeAndUpload(err, data, { tempFile, bucketName, fileName}));

    callback(null);
};
