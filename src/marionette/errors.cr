module Marionette
  class Error < Exception
    enum Code
      Success                         =   0
      NoSuchElement                   =   7 # no such element
      NoSuchFrame                     =   8 # no such frame
      UnknownCommand                  =   9 # unknown command
      StaleElementReference           =  10 # stale element reference
      ElementNotVisible               =  11 # element not visible
      InvalidElementState             =  12 # invalid element state
      UnknownError                    =  13 # unknown error
      ElementIsNotSelectable          =  15 # element not selectable
      JavascriptError                 =  17 # javascript error
      XpathLookupError                =  19 # invalid selector
      Timeout                         =  21 # timeout
      NoSuchWindow                    =  23 # no such window
      InvalidCookieDomain             =  24 # invalid cookie domain
      UnableToSetCookie               =  25 # unable to set cookie
      UnexpectedAlertOpen             =  26 # unexpected alert open
      NoAlertOpen                     =  27 # no such alert
      ScriptTimeout                   =  28 # script timeout
      InvalidElementCoordinates       =  29 # invalid element coordinates
      ImeNotAvailable                 =  30 # ime not available
      ImeEngineActivationFailed       =  31 # ime engine activation failed
      InvalidSelector                 =  32 # invalid selector
      SessionNotCreated               =  33 # session not created
      MoveTargetOutOfBounds           =  34 # move target out of bounds
      InvalidXpathSelector            =  51 # invalid selector
      InvalidXpathSelectorReturnTyper =  52 # invalid selector
      ElementNotInteractable          =  60 # element not interactable
      InvalidArgument                 =  61 # invalid argument
      NoSuchCookie                    =  62 # no such cookie
      UnableToCaptureScreen           =  63 # unable to capture screen
      ElementClickIntercepted         =  64 # element click intercepted
      InsecureCertificate             =  65 # insecure certificate
      InvalidCoordinates              =  66 # invalid coordinates
      InvalidSessionId                =  67 # invalid session id
      UnknownMethod                   =  68 # unknown method exception
      MethodNotAllowed                = 405 # unsupported operation
      GenericError                    = 406
    end
  end
end
