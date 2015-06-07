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

  lpr9201Driver = new Lpr9201.Driver '/dev/tty.usbserial-A7YU3BML', {baudrate: 9600}


  lpr9201Driver.on 'open' () ->
    console.log 'lpr9201 open'

  lpr9201Driver.on 'close' () ->
    console.log 'lpr9201 close'

  lpr9201Driver.on 'error' () ->
    console.log 'lpr9201 error'

  lpr9201Driver.on 'data' () ->
    console.log 'lpr9201 data'

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

    socket.on 'execute', (data) ->
      console.log data
      commandExecute data.command

    socket.on 'disconnect', ->
      console.log 'web interface disconnect'


  power = 1


  ledControllers = []




  udpPort = new Osc.UDPPort {
    localAddress: '0.0.0.0',
    localPort: 8000
  }

  udpPort.on 'message', (message) ->
    console.log message

    index = message.address.replace '/ball/', ''

    index = parseInt index
    colors = message.args

    io.sockets.emit('led', {
      index: index,
      colors: colors
    })

  udpPort.open()



  robot.hear /value (\d+) (\d+) (\d+) (\d+)/i, (res) ->
    console.log('value')

    lpr9201.send.dataTransmission 0xFFFF, [
      parseInt res.match[1]
      parseInt res.match[2]
      parseInt res.match[3]
      parseInt res.match[4]
    ], false, false, true


  robot.hear /red/i, (res) ->
    console.log('red')
    sendAll(0xFF, 0x00, 0x00)

  robot.hear /green/i, (res) ->
    console.log('green')
    sendAll(0x00, 0xFF, 0x00)

  robot.hear /blue/i, (res) ->
    console.log('blue')
    sendAll(0x00, 0x00, 0xFF)

  robot.hear /black/i, (res) ->
    console.log('blue')
    sendAll(0x00, 0x00, 0x00)

  robot.hear /^led$/i, (res) ->
    sendAll(0x00, 0x00, 0x00)

  robot.hear /led (\d+) (\d+) (\d+) (\d+)\s*/i, (res) ->
    index = parseInt res.match[1]
    red = parseInt res.match[2]
    green = parseInt res.match[3]
    blue = parseInt res.match[4]

    index -= 1

    send index, red, green, blue

  robot.hear /ledall (\d+) (\d+) (\d+)\s*/i, (res) ->
    red = parseInt res.match[1]
    green = parseInt res.match[2]
    blue = parseInt res.match[3]

    sendAll red, green, blue

  robot.hear /power (\d+)\s*/i, (res) ->
    p = parseInt res.match[1]
    power = p / 100
    console.log power

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

