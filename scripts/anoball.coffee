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

  #lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254T2', {baudrate: 9600}, true
  #lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254T2', {baudrate: 230400}, true

  lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254TU', {baudrate: 9600}, true
  lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A90254TU', {baudrate: 230400}, true


  lpr9201Driver.on 'open', () ->
    lpr9201Driver.send.activateRequest()
    console.log 'lpr9201 open'

  lpr9201Driver.on 'close', () ->
    console.log 'lpr9201 close'

  lpr9201Driver.on 'error', () ->
    console.log 'lpr9201 error'

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


  power = 1


  ledControllers = []




  udpPort = new Osc.UDPPort {
    localAddress: '0.0.0.0',
    localPort: 8000
  }

  udpPort.on 'message', (message) ->
    #console.log message

    match = message.address.match /\/ball\/(\d+)/

    if !match
      return

    index = parseInt match[1]
    colors = message.args

    io.sockets.emit('led', {
      index: index,
      colors: colors
    })

    arr = []

    for c in message.args
      arr.push (c >> 16) & 0xFF
      arr.push (c >> 8) & 0xFF
      arr.push (c >> 0) & 0xFF

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

    if maps[index]
      lpr9201Driver.send.dataTransmission maps[index], arr, false, false, false
      #lpr9201Driver.send.dataTransmission maps[index], arr, false, false, true


  udpPort.open()


  ###
  colorApply(num) ->
    red = (num >> 16) & 0xFF
    green = (num >> 8) & 0xFF
    blue = (num >> 0) & 0xFF

    lpr9201Driver.send.dataTransmission 0x0001, [
      0x00,
      0x00,
      red,
      0x00,
    ], false, false, true
  ###





###############

  robot.hear /baton connect/i, (msg) ->
    serialPort.open () ->
      msg.send 'connected'


  robot.hear /baton disconnect/i, (msg) ->
    serialPort.close () ->
      msg.send 'disconnected'


  robot.hear /baton setup/i, (msg) ->
    lpr9201Driver.send.readProfile 1

    setTimeout ->
      lpr9201Driver.send.activateRequest()
    , 2000

  robot.hear /baton activate/i, (msg) ->
    lpr9201Driver.send.activateRequest()

  robot.hear /baton reset/i, (msg) ->
    lpr9201Driver.send.reset()

  robot.hear /baton profile read (\d+)/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.readProfile(num)

  robot.hear /baton profile write (\d+)/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.writeProfile(num)

  robot.hear /baton parameter reset/i, (msg) ->
    lpr9201Driver.send.resetProfile()

  robot.hear /baton parameter read (\d+)/i, (msg) ->
    num = parseInt msg.match[1]
    lpr9201Driver.send.readProfileParameter(num)

  robot.hear /baton parameter write (\d+) (\d+)/i, (msg) ->
    key = parseInt msg.match[1]
    value = parseInt msg.match[2]
    lpr9201Driver.send.writeProfileParameter(key, value)

  robot.hear /baton status/i, (msg) ->
    msg.send "baton status"
    lpr9201Driver.send.connectionConfirmation()


###############


  robot.hear /j/i, (res) ->
    console.log 'send'

    arr = []

    for i in [0..11]
      arr.push i * 20
      arr.push 0
      arr.push 0

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true



  robot.hear /k/i, (res) ->
    console.log 'send'

    arr = []

    for i in [0..11]
      arr.push i * 20
      arr.push 0
      arr.push 255 - i * 20

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true


  #
  robot.hear /r/i, (res) ->
    arr = []
    for i in [0..11]
      arr.push 0xFF * power
      arr.push 0x00 * power
      arr.push 0x00 * power

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true
    #lpr9201Driver.send.dataTransmission 1011, arr, false, false, false

  #
  robot.hear /g/i, (res) ->
    arr = []
    for i in [0..11]
      arr.push 0x00
      arr.push 0xFF
      arr.push 0x00

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true


  #
  robot.hear /b/i, (res) ->
    arr = []
    for i in [0..11]
      arr.push 0x00
      arr.push 0x00
      arr.push 0xFF

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true


  #
  robot.hear /x/i, (res) ->
    arr = []
    for i in [0..11]
      arr.push 0x00
      arr.push 0x00
      arr.push 0x00

    lpr9201Driver.send.dataTransmission 0x0001, arr, false, false, true


  #
  robot.hear /green/i, (res) ->
    console.log('green')
    sendAll(0x00, 0xFF, 0x00)


  #
  robot.hear /blue/i, (res) ->
    console.log('blue')
    sendAll(0x00, 0x00, 0xFF)


  #
  robot.hear /black/i, (res) ->
    console.log('blue')
    sendAll(0x00, 0x00, 0x00)


  #
  robot.hear /^led$/i, (res) ->
    sendAll(0x00, 0x00, 0x00)


  #
  robot.hear /led (\d+) (\d+) (\d+) (\d+)\s*/i, (res) ->
    index = parseInt res.match[1]
    red = parseInt res.match[2]
    green = parseInt res.match[3]
    blue = parseInt res.match[4]

    index -= 1

    send index, red, green, blue


  #
  robot.hear /ledall (\d+) (\d+) (\d+)\s*/i, (res) ->
    red = parseInt res.match[1]
    green = parseInt res.match[2]
    blue = parseInt res.match[3]

    sendAll red, green, blue


  #
  robot.hear /power (\d+)\s*/i, (res) ->
    p = parseInt res.match[1]
    power = p / 100
    console.log power


  #
  send = (index, red, green, blue) ->
    red /= 2
    green /= 2
    blue /= 2

    red *= power
    green *= power
    blue *= power

    red = Math.floor red
    green = Math.floor green
    blue = Math.floor blue

    console.log index, red, green, blue

    for ledController, i in ledControllers
      _index = index - i * 4

      if _index >= 0 && _index < 4
        #console.log index, red, green, blue
        ledController.write(new Buffer([_index, red, green, blue]))

  sendAll = (red, green, blue) ->
    ledcount = 8

    for i in [0..ledcount-1]
      send i, red, green, blue


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
    sendColor id, color, true


  # 全てのノードに色を送る
  sendColorBroadcast = (color) ->
    sendColor 0xFFFF, color, true


  # ノードに色を送る
  sendColor = (id, color, isBroadcast) ->
    arr = []

    for i in [0..11]
      arr.push (color >> 16) & 0xFF
      arr.push (color >> 8) & 0xFF
      arr.push (color >> 0) & 0xFF

    sendColors id, colors, isBroadcast

  #####

  # 指定IDのノードに色を送る
  sendColorsById = (id, colors) ->
    sendColors id, colors, false


  # 全てのノードに色を送る
  sendColorsBroadcast = (colors) ->
    sendColors 0xFFFF, colors, true


  # ノードに色を送る
  sendColors = (id, colors, isBroadcast) ->
    arr = []

    for color in colors
      arr.push (color >> 16) & 0xFF
      arr.push (color >> 8) & 0xFF
      arr.push (color >> 0) & 0xFF

    lpr9201Driver.send.dataTransmission id, arr, false, false, isBroadcast
