AWS         = require "aws-sdk"
busboy      = require "express-busboy"
express     = require "express"
fs          = require "fs"
gm          = require "gm"
pngquant    = require "node-pngquant-native"
serveStatic = require "serve-static"

accessKeyId     = process.env.AWS_S3_ACCESS_KEY
acl             = process.env.AWS_S3_ACL || "public-read"
bucket          = process.env.AWS_S3_BUCKET || "gyazobank"
endpoint        = process.env.AWS_S3_ENDPOINT
secretAccessKey = process.env.AWS_S3_SECRET_KEY

s3 = new AWS.S3
  endpoint: new AWS.Endpoint endpoint
  accessKeyId: accessKeyId
  secretAccessKey: secretAccessKey

app = express()
app.use serveStatic "public"
busboy.extend app, {
  upload: true
}

app.post "/upload", (req, res) ->
  url = ""

  if not req.files.imagedata
    return res.send url

  filepath = req.files.imagedata.file

  name = "#{ req.files.imagedata.uuid }.png"
  url = "http://#{ bucket }.#{ endpoint }/#{ name }"

  fs.readFile filepath, (err, buffer) ->
    if err
      return res.send ""

    gm(buffer)
      .options(imageMagick: true)
      .autoOrient()
      .toBuffer "PNG", (err, pngBuffer) ->
        if err
          return res.send ""

        s3.putObject {
          ACL: acl
          Body: pngquant.compress pngBuffer
          Bucket: bucket
          Key: name
          ContentType: "image/png"
        }, (err, data) ->
          if err
            console.log err
            res.send ""
          else
            res.send url

app.listen process.env.PORT || 3000

