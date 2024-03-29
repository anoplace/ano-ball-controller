# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
  Fs = require 'fs'
  SocketIo = require 'socket.io'
  Osc = require 'osc'
  Lpr9201 = require 'lpr9201'
  Result = Lpr9201.Result

  #lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90253N1', {baudrate: 9600}, true
  lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90253N1', {baudrate: 230400}, true

  #lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254TU', {baudrate: 9600}, true
  #lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254TU', {baudrate: 230400}, true


  lpr9201Driver.on 'open', () ->
    lpr9201Driver.send.activateRequest()
    console.log 'lpr9201 open'

  lpr9201Driver.on 'close', () ->
    console.log 'lpr9201 close'

  lpr9201Driver.on 'error', (e) ->
    console.log 'lpr9201 error', e

  lpr9201Driver.on 'data', (data) ->
    if Result.Ack.canParse(data)
      console.log 'Ack'

    else if Result.ConnectionConfirmation.canParse(data)
      console.log 'ConnectionConfirmation'
      lpr9201Driver.send.activateRequest()

    else if Result.EdScan.canParse(data)
      edScan = new Result.EdScan(data);
      console.log 'EdScan', edScan.value

    else if (Result.Nack.canParse(data))
      nack = new Result.Nack(data)
      console.log 'Nack', nack.reasonCode

    else if Result.ProfileParameterResult.canParse(data)
      profileParameterResult = new Result.ProfileParameterResult(data)
      console.log 'ProfileParameterResult', profileParameterResult.value

    else if (Result.ReceiveData.canParse(data))
      receiveData = new Result.ReceiveData(data)
      console.log 'ReceiveData', receiveData.datas

    else if (Result.Ring.canParse(data))
      console.log 'Ring'
      lpr9201Driver.send.readReceiveData()

    else if (Result.Rssi.canParse(data))
      rssi = new Result.Rssi(data)
      console.log 'Rssi', rssi.value

    else if (Result.Wup.canParse(data))
      console.log 'Wup'


  io = SocketIo.listen(robot.server)

  io.on 'connection', (socket) ->
    console.log 'web interface connection'

    socket.on 'led', (data) ->
      console.log data

    socket.on 'disconnect', ->
      console.log 'web interface disconnect'


  time = 0
  power = 0.8
  nodeId = 1001
  duration = 1000


  udpPort = new Osc.UDPPort {
    localAddress: '0.0.0.0',
    localPort: 8000
  }

  udpPort.on 'message', (message) ->
    console.log message

    match = message.address.match /\/ball\/(\d+)/

    if !match
      return


    if + new Date() - time < 30
      return

    time = + new Date()


    index = parseInt match[1]
    broadcast = message.args.shift()
    duration = message.args.shift()
    colors = message.args

    io.sockets.emit('led', {
      index: index,
      colors: colors
    })

    # 1001
    # 1002
    # 1003
    # 1005
    # 1006
    # 1011

    maps = [
      1001, # 0
      1002, # 1
      1003, # 2
      1004, # 3
      1005, # 4
      1006, # 5
      1007, # 6
      1008, # 7
      1009, # 8
      1011, # 9
    ]

    if broadcast
      sendColorsBroadcast colors
    else
      if maps[index]
        sendColorsById maps[index], colors

  udpPort.open()

###############

  robot.hear /^lpr9201 connect$/i, (msg) ->
    serialPort.open () ->
      msg.send 'connected'

  robot.hear /^lpr9201 disconnect$/i, (msg) ->
    serialPort.close () ->
      msg.send 'disconnected'

  robot.hear /^lpr9201 setup$/i, (msg) ->
    lpr9201Driver.send.readProfile 1

    setTimeout ->
      lpr9201Driver.send.activateRequest()
    , 2000

  robot.hear /^lpr9201 activate$/i, (msg) ->
    lpr9201Driver.send.activateRequest()

  robot.hear /^lpr9201 reset$/i, (msg) ->
    lpr9201Driver.send.reset()

  robot.hear /^lpr9201 profile read (\d+)$/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.readProfile(num)

  robot.hear /^lpr9201 profile write (\d+)$/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.writeProfile(num)

  robot.hear /^lpr9201 parameter reset$/i, (msg) ->
    lpr9201Driver.send.resetProfile()

  robot.hear /^lpr9201 parameter read (\d+)$/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.readProfileParameter(num)

  robot.hear /^lpr9201 parameter write (\d+) (\d+)$/i, (msg) ->
    key = parseInt msg.match[1]
    value = parseInt msg.match[2]
    lpr9201Driver.send.writeProfileParameter(key, value)

  robot.hear /^lpr9201 status$/i, (msg) ->
    msg.send "lpr9201 status"
    lpr9201Driver.send.connectionConfirmation()

###############

  robot.hear /^id$/i, (res) ->
    console.log nodeId

  robot.hear /^id (\d+)$/i, (res) ->
    nodeId = parseInt res.match[1]
    console.log nodeId

  robot.hear /^duration$/i, (res) ->
    console.log duration

  robot.hear /^duration (\d+)$/i, (res) ->
    duration = parseInt res.match[1]
    console.log duration

  robot.hear /^rgb 0x(\w+)$/, (res) ->
    c = parseInt res.match[1], 16
    sendColorById nodeId, c

  robot.hear /^RGB 0x(\w+)$/, (res) ->
    c = parseInt res.match[1], 16
    sendColorBroadcast c

  robot.hear /^r$/, (res) ->
    sendColorById nodeId, 0xFF0000

  robot.hear /^R$/, (res) ->
    sendColorBroadcast 0xFF0000

  robot.hear /^g$/, (res) ->
    sendColorById nodeId, 0x00FF00

  robot.hear /^G/, (res) ->
    sendColorBroadcast 0x00FF00

  robot.hear /^b$/, (res) ->
    sendColorById nodeId, 0x0000FF

  robot.hear /^B/, (res) ->
    sendColorBroadcast 0x0000FF

  robot.hear /^x$/, (res) ->
    sendColorById nodeId, 0x000000

  robot.hear /^X/, (res) ->
    sendColorBroadcast 0x000000


  robot.hear /^g 0x(\w+) (\d+)$/i, (res) ->
    arr = [
      0x000000,
      0x000000,
      0x000000,
      0x000000,
      0x000000,

      0x000000,
      0x000000,
      0x000000,
      0x000000,
      0x000000,

      0x000000,
      0x000000,
    ]

    color = parseInt res.match[1], 16
    index = parseInt res.match[2]

    arr[index] = color

    console.log arr

    #sendColorsById nodeId, arr
    sendColorsBroadcast arr



  robot.hear /^g1$/i, (res) ->
    arr = []

    for i in [0..11]
      red = i * 20
      green = 0
      blue = 255 - i * 20

      arr.push (red << 16 | green << 8 | blue << 0)

    sendColorsById nodeId, arr


  robot.hear /^g2$/i, (res) ->
    arr = []

    for i in [0..11]
      red = i * 20
      green = 255 - i * 20
      blue = 0

      arr.push (red << 16 | green << 8 | blue << 0)

    sendColorsById nodeId, arr


  robot.hear /^g3$/i, (res) ->
    arr = []

    for i in [0..11]
      red = 0
      green = 255 - i * 20
      blue = i * 20

      arr.push (red << 16 | green << 8 | blue << 0)

    sendColorsById nodeId, arr


  robot.hear /^g4$/i, (res) ->
    arr = [
      0xFF0000,
      0xFF0000,
      0xFF0000,
      0xFF0000,
      0xFF0000,

      0x0000FF,
      0x0000FF,
      0x0000FF,
      0x0000FF,
      0x0000FF,

      0x0000FF,
      0x0000FF,
    ]

    sendColorsById nodeId, arr


  robot.hear /^g5$/i, (res) ->
    arr = [
      0xFF0000,
      0xFF0000,
      0xFF0000,
      0xFF0000,
      0xFF0000,

      0x00FF00,
      0x00FF00,
      0x00FF00,
      0x00FF00,
      0x00FF00,

      0x00FF00,
      0x00FF00,
    ]

    sendColorsById nodeId, arr


  robot.hear /^w (\d+)$/i, (res) ->
    arr = [
      0x000000,
      0x000000,
      0x000000,
      0x000000,
      0x000000,

      0x000000,
      0x000000,
      0x000000,
      0x000000,
      0x000000,

      0x000000,
      0x000000,
    ]

    index = parseInt res.match[1]
    arr[index] = 0x0000FF

    sendColorsById nodeId, arr


  #
  robot.hear /^power$|^p$/i, (res) ->
    console.log power

  robot.hear /^power (\d+)$|^p (\d+)$/i, (res) ->
    p = parseInt res.match[1] || res.match[2]
    power = p / 100
    console.log power


  #
  robot.router.get "/anoball", (req, res, next) ->
    res.setHeader 'content-type', 'text/html'
    res.end Fs.readFileSync('./scripts/index.html')


  # initialize
  do ->
    #lpr9201Driver.open () ->
    #  lpr9201Driver.send.readProfile 1

    #  setTimeout ->
    #    lpr9201Driver.send.activateRequest()
    #  , 2000


  # 指定IDのノードに色を送る
  sendColorById = (id, color) ->
    sendColor id, color, false


  # 全てのノードに色を送る
  sendColorBroadcast = (color) ->
    sendColor 0xFFFF, color, true


  # ノードに色を送る
  sendColor = (id, color, isBroadcast) ->
    arr = []

    for i in [0..11]
      arr.push color

    sendColors id, arr, isBroadcast

  #####

  # 指定IDのノードに色を送る
  sendColorsById = (id, colors) ->
    sendColors id, colors, false


  # 全てのノードに色を送る
  sendColorsBroadcast = (colors) ->
    sendColors 0xFFFF, colors, true


  # ノードに色を送る
  sendColors = (id, colors, isBroadcast) ->
    console.log 'send to lpr9201'
    arr = [
      (duration >> 8) & 0xFF,
      (duration >> 0) & 0xFF,
    ]

    for color in colors
      arr.push (color >> 16) & 0xFF * power  # red
      arr.push (color >> 8) & 0xFF * power  # green
      arr.push (color >> 0) & 0xFF * power  # blue


    #console.log colors
    #console.log arr
    #console.log arr.length

    lpr9201Driver.send.dataTransmission id, arr, false, false, isBroadcast
