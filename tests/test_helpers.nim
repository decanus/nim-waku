import
  unittest, chronos, bearssl,
  eth/[keys, p2p]

import libp2p/crypto/crypto

var nextPort = 30303

proc localAddress*(port: int): Address =
  let port = Port(port)
  result = Address(udpPort: port, tcpPort: port,
                   ip: parseIpAddress("127.0.0.1"))

proc setupTestNode*(
    rng: ref BrHmacDrbgContext,
    capabilities: varargs[ProtocolInfo, `protocolInfo`]): EthereumNode =
  let keys1 = keys.KeyPair.random(rng[])
  result = newEthereumNode(keys1, localAddress(nextPort), 1, nil,
                           addAllCapabilities = false, rng = rng)
  nextPort.inc
  for capability in capabilities:
    result.addCapability capability

template asyncTest*(name, body: untyped) =
  test name:
    proc scenario {.async.} = body
    waitFor scenario()

template procSuite*(name, body: untyped) =
  proc suitePayload =
    suite name:
      body

  suitePayload()

type RngWrap = object
  rng: ref BrHmacDrbgContext

var rngVar: RngWrap

proc getRng(): ref BrHmacDrbgContext =
  # TODO if `rngVar` is a threadvar like it should be, there are random and
  #      spurious compile failures on mac - this is not gcsafe but for the
  #      purpose of the tests, it's ok as long as we only use a single thread
  {.gcsafe.}:
    if rngVar.rng.isNil:
      rngVar.rng = crypto.newRng()
    rngVar.rng

template rng*(): ref BrHmacDrbgContext =
  getRng()