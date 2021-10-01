import # std libs
  std/[json, options, os, unittest]

import ../status/status
import ../status/types/[keycard]
import ../status/keycard as keycard_module

suite "#Keycard":
  setup:
    let fleetConfig = "{\"fleets\":{\"eth.prod\":{\"boot\":{\"boot-01.ac-cn-hongkong-c.eth.prod\":\"enode://6e6554fb3034b211398fcd0f0082cbb6bd13619e1a7e76ba66e1809aaa0c5f1ac53c9ae79cf2fd4a7bacb10d12010899b370c75fed19b991d9c0cdd02891abad@47.75.99.169:443\"},\"mail\":{\"mail-01.ac-cn-hongkong-c.eth.prod\":\"enode://606ae04a71e5db868a722c77a21c8244ae38f1bd6e81687cc6cfe88a3063fa1c245692232f64f45bd5408fed5133eab8ed78049332b04f9c110eac7f71c1b429@47.75.247.214:443\"},\"rendezvous\":{\"boot-01.ac-cn-hongkong-c.eth.prod\":\"/ip4/47.75.99.169/tcp/30703/ethv4/16Uiu2HAmV8Hq9e3zm9TMVP4zrVHo3BjqW5D6bDVV6VQntQd687e4\"},\"whisper\":{\"node-01.ac-cn-hongkong-c.eth.prod\":\"enode://b957e51f41e4abab8382e1ea7229e88c6e18f34672694c6eae389eac22dab8655622bbd4a08192c321416b9becffaab11c8e2b7a5d0813b922aa128b82990dab@47.75.222.178:443\"}}},\"meta\":{\"hostname\":\"node-01.do-ams3.proxy.misc\",\"timestamp\":\"2021-09-09T00:00:14.760436\"}}";
    let statuslib_instance = newStatusInstance(fleetConfig, "mock")

  test "start: should start listening to keycards":
    try:
      statuslib_instance.keycard.start()
    except KeycardStartException as ex:
      echo "keycard start exception"
      echo repr(ex)
    except KeycardException as ex:
      echo "keycard exception"
      echo repr(ex)

  test "select: should return KeycardApplicationInfo":
    try:
      statuslib_instance.keycard.start()
      let info = statuslib_instance.keycard.select()
      statuslib_instance.keycard.stop()
      check(info.installed)
    except KeycardStartException as ex:
      echo "keycard start exception"
      echo repr(ex)
    except KeycardStopException as ex:
      echo "keycard stop exception"
      echo repr(ex)
    except KeycardException as ex:
      echo "keycard exception"
      echo repr(ex)

  test "stop: should stop listening to keycards":
    try:
      statuslib_instance.keycard.start()
      statuslib_instance.keycard.stop()
    except KeycardStartException as ex:
      echo "keycard start exception"
      echo repr(ex)
    except KeycardStopException as ex:
      echo "keycard stop exception"
      echo repr(ex)
    except KeycardSelectException as ex:
      echo "keycard select exception"
      echo repr(ex)
    except KeycardException as ex:
      echo "keycard exception"
      echo repr(ex)
