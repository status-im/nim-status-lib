import keycard_go
import ../types/keycard
import ../backends/backend

include utils/json_utils

type KeycardModel* = ref object
  backend*: Backend

proc newKeycardModel*(backend: Backend): KeycardModel =
  result = KeycardModel()
  result.backend = backend

proc start*(self: KeycardModel) =
  try:
    self.backend.keycardStart()
  except:
    raise

proc stop*(self: KeycardModel) =
  try:
    self.backend.keycardStop()
  except:
    raise

proc select*(self: KeycardModel): KeycardApplicationInfo =
  try:
    result = self.backend.keycardSelect()
  except:
    raise

proc pair*(self: KeycardModel, pairingPassword: string): KeycardPairingInfo =
  try:
    result = self.backend.keycardPair(pairingPassword)
  except:
    raise

proc openSecureChannel*(self: KeycardModel, index: int, key: string) =
  try:
    self.backend.keycardOpenSecureChannel(index, key)
  except:
    raise

proc verifyPIN*(self: KeycardModel, pin: string) =
  try:
    self.backend.keycardVerifyPIN(pin)
  except:
    raise

proc exportKey*(self: KeycardModel): string =
  try:
    result = self.backend.keycardExportKey()
  except:
    raise
