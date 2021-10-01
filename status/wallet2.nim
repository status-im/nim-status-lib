import json, strformat, options, chronicles, sugar, sequtils, strutils

import statusgo_backend/accounts as status_accounts
import statusgo_backend/constants as constants
import statusgo_backend/wallet as status_wallet
import statusgo_backend/network as status_network
import statusgo_backend/settings as status_settings
import eth/contracts
import wallet2/balance_manager
import eth/tokens as tokens_backend
import wallet2/account as wallet_account
import ./types/[account, transaction, network, network_type, setting, gas_prediction, rpc_response]
import ../eventemitter
from web3/ethtypes import Address
from web3/conversions import `$`

export wallet_account

logScope:
  topics = "status-wallet2"

type
  CryptoServicesArg* = ref object of Args
    services*: JsonNode # an array

type 
  Wallet2Model* = ref object
    events: EventEmitter
    accounts: seq[WalletAccount]
    networks*: seq[Network]
    tokens: seq[Erc20Contract]
    totalBalance*: float

# Forward declarations
proc initEvents*(self: Wallet2Model)
proc generateAccountConfiguredAssets*(self: Wallet2Model, 
  accountAddress: string): seq[Asset]
proc calculateTotalFiatBalance*(self: Wallet2Model)

proc setup(self: Wallet2Model, events: EventEmitter) = 
  self.events = events
  self.accounts = @[]
  self.tokens = @[]
  self.networks = @[]
  self.totalBalance = 0.0
  self.initEvents()

proc delete*(self: Wallet2Model) =
  discard

proc newWallet2Model*(events: EventEmitter): Wallet2Model =
  result = Wallet2Model()
  result.setup(events)

proc initTokens(self: Wallet2Model) =
  let network = status_settings.getCurrentNetwork().toNetwork()
  self.tokens = tokens_backend.getVisibleTokens(network)

proc initNetworks(self: Wallet2Model) =
  self.networks = status_network.getNetworks()

proc initAccounts(self: Wallet2Model) =
  let accounts = status_wallet.getWalletAccounts()
  for acc in accounts:
    var assets: seq[Asset] = self.generateAccountConfiguredAssets(acc.address)
    var walletAccount = newWalletAccount(acc.name, acc.address, acc.iconColor, 
    acc.path, acc.walletType, acc.publicKey, acc.wallet, acc.chat, assets)
    self.accounts.add(walletAccount)

proc init*(self: Wallet2Model) =
  self.initTokens()
  self.initNetworks()
  self.initAccounts()

proc initEvents*(self: Wallet2Model) = 
  self.events.on("wallet2_currencyChanged") do(e: Args):
    self.events.emit("wallet2_accountsUpdated", Args())

  self.events.on("wallet2_newAccountAdded") do(e: Args):
    self.calculateTotalFiatBalance()

proc getAccounts*(self: Wallet2Model): seq[WalletAccount] =
  self.accounts

proc getDefaultCurrency*(self: Wallet2Model): string =
# TODO: this should come from a model? It is going to be used too in the
# profile section and ideally we should not call the settings more than once
  status_settings.getSetting[string](Setting.Currency, "usd")

proc generateAccountConfiguredAssets*(self: Wallet2Model, 
  accountAddress: string): seq[Asset] =
  var assets: seq[Asset] = @[]
  var asset = Asset(name:"Ethereum", symbol: "ETH", value: "0.0", 
  fiatBalanceDisplay: "0.0", accountAddress: accountAddress)
  assets.add(asset)
  for token in self.tokens:
    var symbol = token.symbol
    var existingToken = Asset(name: token.name, symbol: symbol, 
    value: fmt"0.0", fiatBalanceDisplay: "$0.0", accountAddress: accountAddress, 
      address: $token.address)
    assets.add(existingToken)
  assets

proc calculateTotalFiatBalance*(self: Wallet2Model) =
  self.totalBalance = 0.0
  for account in self.accounts:
    if account.realFiatBalance.isSome:
      self.totalBalance += account.realFiatBalance.get()

proc newAccount*(self: Wallet2Model, walletType: string, derivationPath: string, 
  name: string, address: string, iconColor: string, balance: string, 
  publicKey: string): WalletAccount =
  var assets: seq[Asset] = self.generateAccountConfiguredAssets(address)
  var account = WalletAccount(name: name, path: derivationPath, walletType: walletType, 
  address: address, iconColor: iconColor, balance: none[string](), assetList: assets, 
  realFiatBalance: none[float](), publicKey: publicKey)
  updateBalance(account, self.getDefaultCurrency())
  account

proc addNewGeneratedAccount(self: Wallet2Model, generatedAccount: GeneratedAccount, 
  password: string, accountName: string, color: string, accountType: string, 
  isADerivedAccount = true, walletIndex: int = 0) =
  try:
    generatedAccount.name = accountName
    var derivedAccount: DerivedAccount = status_accounts.saveAccount(generatedAccount, 
    password, color, accountType, isADerivedAccount, walletIndex)
    var account = self.newAccount(accountType, derivedAccount.derivationPath, 
    accountName, derivedAccount.address, color, fmt"0.00 {self.getDefaultCurrency()}", 
    derivedAccount.publicKey)

    self.accounts.add(account)
    # wallet_checkRecentHistory is required to be called when a new account is
    # added before wallet_getTransfersByAddress can be called. This is because
    # wallet_checkRecentHistory populates the status-go db that
    # wallet_getTransfersByAddress reads from
    discard status_wallet.checkRecentHistory(self.accounts.map(account => account.address))
    self.events.emit("wallet2_newAccountAdded", wallet_account.AccountArgs(account: account))
  except Exception as e:
    raise newException(StatusGoException, fmt"Error adding new account: {e.msg}")

proc generateNewAccount*(self: Wallet2Model, password: string, accountName: string, color: string) =
  let
    walletRootAddress = status_settings.getSetting[string](Setting.WalletRootAddress, "")
    walletIndex = status_settings.getSetting[int](Setting.LatestDerivedPath) + 1
    loadedAccount = status_accounts.loadAccount(walletRootAddress, password)
    derivedAccount = status_accounts.deriveWallet(loadedAccount.id, walletIndex)
    generatedAccount = GeneratedAccount(
      id: loadedAccount.id,
      publicKey: derivedAccount.publicKey,
      address: derivedAccount.address
    )

  # if we've gotten here, the password is ok (loadAccount requires a valid password)
  # so no need to check for a valid password
  self.addNewGeneratedAccount(generatedAccount, password, accountName, color, constants.GENERATED, true, walletIndex)
  
  let statusGoResult = status_settings.saveSetting(Setting.LatestDerivedPath, $walletIndex)
  if statusGoResult.error != "":
    error "Error storing the latest wallet index", msg=statusGoResult.error

proc addAccountsFromSeed*(self: Wallet2Model, seed: string, password: string, accountName: string, color: string, keystoreDir: string) =
  let mnemonic = replace(seed, ',', ' ')
  var generatedAccount = status_accounts.multiAccountImportMnemonic(mnemonic)
  generatedAccount.derived = status_accounts.deriveAccounts(generatedAccount.id)

  let
    defaultAccount = status_accounts.getDefaultAccount()
    isPasswordOk = status_accounts.verifyAccountPassword(defaultAccount, password, keystoreDir)
  if not isPasswordOk:
    raise newException(StatusGoException, "Error generating new account: invalid password")

  self.addNewGeneratedAccount(generatedAccount, password, accountName, color, constants.SEED)

proc addAccountsFromPrivateKey*(self: Wallet2Model, privateKey: string, password: string, accountName: string, color: string, keystoreDir: string) =
  let
    generatedAccount = status_accounts.MultiAccountImportPrivateKey(privateKey)
    defaultAccount = status_accounts.getDefaultAccount()
    isPasswordOk = status_accounts.verifyAccountPassword(defaultAccount, password, keystoreDir)

  if not isPasswordOk:
    raise newException(StatusGoException, "Error generating new account: invalid password")

  self.addNewGeneratedAccount(generatedAccount, password, accountName, color, constants.KEY, false)

proc addWatchOnlyAccount*(self: Wallet2Model, address: string, accountName: string, color: string) =
  let account = GeneratedAccount(address: address)
  self.addNewGeneratedAccount(account, "", accountName, color, constants.WATCH, false)

proc changeAccountSettings*(self: Wallet2Model, address: string, accountName: string, color: string): string =
  var selectedAccount: WalletAccount
  for account in self.accounts:
    if (account.address == address):
      selectedAccount = account
      break
  if (isNil(selectedAccount)):
    result = "No account found with that address"
    error "No account found with that address", address
  selectedAccount.name = accountName
  selectedAccount.iconColor = color
  result = status_accounts.changeAccount(selectedAccount.name, selectedAccount.address, 
  selectedAccount.publicKey, selectedAccount.walletType, selectedAccount.iconColor)

proc deleteAccount*(self: Wallet2Model, address: string): string =
  result = status_accounts.deleteAccount(address)
  self.accounts = self.accounts.filter(acc => acc.address.toLowerAscii != address.toLowerAscii)

proc getOpenseaCollections*(address: string): string =
  let networkId = status_settings.getCurrentNetworkDetails().config.networkId
  result = status_wallet.getOpenseaCollections(networkId, address)

proc getOpenseaAssets*(address: string, collectionSlug: string, limit: int): string =
  let networkId = status_settings.getCurrentNetworkDetails().config.networkId
  result = status_wallet.getOpenseaAssets(networkId, address, collectionSlug, limit)

proc onAsyncFetchCryptoServices*(self: Wallet2Model, response: string) =
  let responseArray = response.parseJson
  if (responseArray.kind != JArray):
    info "received crypto services is not a json array"
    self.events.emit("wallet2_cryptoServicesFetched", CryptoServicesArg())
    return

  self.events.emit("wallet2_cryptoServicesFetched", CryptoServicesArg(services: responseArray))

proc toggleNetwork*(self: Wallet2Model, network: Network) =
  network.enabled = not network.enabled
  status_network.upsertNetwork(network)
