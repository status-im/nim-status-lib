import keycard_go
import types/keycard
import ../backends/backend

include utils/json_utils

type
    KeycardModel* = ref object
      backend*: Backend

proc newKeycardModel*(backend: Backend): KeycardModel =
  result = KeycardModel()
  result.backend = backend

proc start*(self: KeycardModel): string =
  result = self.backend.keycardStart()

proc stop*(self: KeycardModel): string =
  result = self.backend.keycardStop()

proc select*(self: KeycardModel): KeycardApplicationInfo =
  result = self.backend.keycardSelect()
