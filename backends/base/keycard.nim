import ../../types/[keycard]
import ../types

method keycardStart*(self: Backend) =
  raise newException(ValueError, "No implementation available")

method keycardStop*(self: Backend) =
  raise newException(ValueError, "No implementation available")

method keycardSelect*(self: Backend): KeycardApplicationInfo =
  raise newException(ValueError, "No implementation available")

method keycardPair*(self: Backend, pairingPassword: string): KeycardPairingInfo =
  raise newException(ValueError, "No implementation available")

method keycardOpenSecureChannel*(self: Backend, index: int, key: string) =
  raise newException(ValueError, "No implementation available")

method keycardVerifyPin*(self: Backend, pin: string) =
  raise newException(ValueError, "No implementation available")

method keycardExportKey*(self: Backend, derive: bool, makeCurrent: bool, onlyPublic: bool, path: string): string =
  raise newException(ValueError, "No implementation available")
