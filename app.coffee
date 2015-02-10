busboy      = require "express-busboy"
express     = require "express"
fs          = require "fs"
gcloud      = require "gcloud"
gm          = require "gm"
serveStatic = require "serve-static"

projectId         = process.env.GCLOUD_PROJECT_ID
credentialKeyFile = process.env.GCLOUD_KEYFILE
bucketName        = process.env.GCLOUD_BUCKET || "gyazobank"
domain            = process.env.DOMAIN || "storage.googleapis.com/#{ bucketName }"

storage = gcloud.storage
  projectId: projectId
  keyFilename: credentialKeyFile

bucket = storage.bucket bucketName

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
  url = "http://#{ domain }/#{ name }"

  fs.readFile filepath, (err, buffer) ->
    if err
      return res.send ""

    gm(buffer)
      .options(imageMagick: true)
      .autoOrient()
      .stream "png", (err, stdout, stderr) ->
        if err
          return res.send ""

        stdout.pipe bucket.file(name).createWriteStream({ "Cache-Control": "public, max-age=31536000" }).on "finish", ->
          res.send url
        .on "error", ->
          res.send ""

app.listen process.env.PORT || 3000

