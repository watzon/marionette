module Marionette
  Commands = {
    "Status"                                 => "status",

    #
    # Session Handling
    #
    "NewSession"                             => "newSession",
    "GetAllSessions"                         => "getAllSessions",
    "DeleteSession"                          => "deleteSession",

    #
    # Basic Driver
    #
    "Get"                                    => "get",
    "GoBack"                                 => "goBack",
    "GoForward"                              => "goForward",
    "Refresh"                                => "refresh",
    "Quit"                                   => "quit",
    "GetTitle"                               => "getTitle",

    #
    # Window and Frame Handling
    #
    "GetCurrentWindowHandle"                 => "getCurrentWindowHandle",
    "W3CgetCurrentWindowHandle"              => "w3cGetCurrentWindowHandle",
    "GetWindowHandles"                       => "getWindowHandles",
    "W3CgetWindowHandles"                    => "w3cGetWindowHandles",
    "NewWindow"                              => "newWindow",
    "Close"                                  => "close",
    "SwitchToWindow"                         => "switchToWindow",
    "SwitchToFrame"                          => "switchToFrame",
    "SwitchToParentFrame"                    => "switchToParentFrame",
    "GetWindowSize"                          => "getWindowSize",
    "W3CgetWindowSize"                       => "w3cGetWindowSize",
    "W3CgetWindowPosition"                   => "w3cGetWindowPosition",
    "GetWindowPosition"                      => "getWindowPosition",
    "SetWindowSize"                          => "setWindowSize",
    "W3CsetWindowSize"                       => "w3cSetWindowSize",
    "SetWindowRect"                          => "setWindowRect",
    "GetWindowRect"                          => "getWindowRect",
    "SetWindowPosition"                      => "setWindowPosition",
    "W3CsetWindowPosition"                   => "w3cSetWindowPosition",
    "MaximizeWindow"                         => "windowMaximize",
    "W3CmaximizeWindow"                      => "w3cMaximizeWindow",
    "FullscreenWindow"                       => "fullscreenWindow",
    "MinimizeWindow"                         => "minimizeWindow",

    #
    # Element
    #
    "FindElement"                            => "findElement",
    "FindElements"                           => "findElements",
    "FindChildElement"                       => "findChildElement",
    "FindChildElements"                      => "findChildElements",
    "ClearElement"                           => "clearElement",
    "ClickElement"                           => "clickElement",
    "SendKeysToElement"                      => "sendKeysToElement",
    "SendKeysToActiveElement"                => "sendKeysToActiveElement",
    "SubmitElement"                          => "submitElement",
    "GetActiveElement"                       => "getActiveElement",
    "W3CgetActiveElement"                    => "w3cGetActiveElement",
    "GetElementText"                         => "getElementText",
    "GetElementValue"                        => "getElementValue",
    "GetElementTagName"                      => "getElementTagName",
    "SetElementSelected"                     => "setElementSelected",
    "IsElementSelected"                      => "isElementSelected",
    "IsElementEnabled"                       => "isElementEnabled",
    "IsElementDisplayed"                     => "isElementDisplayed",
    "GetElementLocation"                     => "getElementLocation",
    "GetElementLocationOnceScrolledIntoView" => "getElementLocationOnceScrolledIntoView",
    "GetElementSize"                         => "getElementSize",
    "GetElementRect"                         => "getElementRect",
    "GetElementAttribute"                    => "getElementAttribute",
    "GetElementProperty"                     => "getElementProperty",
    "GetElementValueOfCssProperty"           => "getElementValueOfCssProperty",
    "ElementScreenshot"                      => "elementScreenshot",

    #
    # Document Handling
    #
    "GetCurrentUrl"                          => "getCurrentUrl",
    "GetPageSource"                          => "getPageSource",
    "ExecuteScript"                          => "executeScript",
    "ExecuteAsyncScript"                     => "executeAsyncScript",
    "W3CexecuteScript"                       => "w3cExecuteScript",
    "W3CexecuteScriptAsync"                  => "w3cExecuteScriptAsync",
    "UploadFile"                             => "uploadFile",
    "Screenshot"                             => "screenshot",

    #
    # Cookies
    #
    "AddCookie"                              => "addCookie",
    "GetCookie"                              => "getCookie",
    "GetAllCookies"                          => "getCookies",
    "DeleteCookie"                           => "deleteCookie",
    "DeleteAllCookies"                       => "deleteAllCookies",

    #
    # Timeouts
    #
    "SetTimeouts"                            => "setTimeouts",
    "SetScriptTimeout"                       => "setScriptTimeout",
    "ImplicitWait"                           => "implicitlyWait",

    #
    # Logs
    #
    "GetLog"                                 => "getLog",
    "GetAvailableLogTypes"                   => "getAvailableLogTypes",

    #
    # Alerts
    #
    "DismissAlert"        => "dismissAlert",
    "W3CdismissAlert"     => "w3cDismissAlert",
    "AcceptAlert"         => "acceptAlert",
    "W3CacceptAlert"      => "w3cAcceptAlert",
    "SetAlertValue"       => "setAlertValue",
    "W3CsetAlertValue"    => "w3cSetAlertValue",
    "GetAlertText"        => "getAlertText",
    "W3CgetAlertText"     => "w3cGetAlertText",
    "SetAlertCredentials" => "setAlertCredentials",

    #
    # Advanced user interactions
    #
    "W3Cactions"      => "actions",
    "W3CclearActions" => "clearActionState",
    "Click"           => "mouseClick",
    "DoubleClick"     => "mouseDoubleClick",
    "MouseDown"       => "mouseButtonDown",
    "MouseUp"         => "mouseButtonUp",
    "MoveTo"          => "mouseMoveTo",

    #
    # Screen Orientation
    #
    "SetScreenOrientation" => "setScreenOrientation",
    "GetScreenOrientation" => "getScreenOrientation",

    #
    # Touch Actions
    #
    "SingleTap"   => "touchSingleTap",
    "TouchDown"   => "touchDown",
    "TouchUp"     => "touchUp",
    "TouchMove"   => "touchMove",
    "TouchScroll" => "touchScroll",
    "DoubleTap"   => "touchDoubleTap",
    "LongPress"   => "touchLongPress",
    "Flick"       => "touchFlick",

    #
    # Html 5
    #
    "ExecuteSql" => "executeSql",

    "GetLocation" => "getLocation",
    "SetLocation" => "setLocation",

    "GetAppCache"       => "getAppCache",
    "GetAppCacheStatus" => "getAppCacheStatus",
    "ClearAppCache"     => "clearAppCache",

    "GetLocalStorageItem"    => "getLocalStorageItem",
    "RemoveLocalStorageItem" => "removeLocalStorageItem",
    "GetLocalStorageKeys"    => "getLocalStorageKeys",
    "SetLocalStorageItem"    => "setLocalStorageItem",
    "ClearLocalStorage"      => "clearLocalStorage",
    "GetLocalStorageSize"    => "getLocalStorageSize",

    "GetSessionStorageItem"    => "getSessionStorageItem",
    "RemoveSessionStorageItem" => "removeSessionStorageItem",
    "GetSessionStorageKeys"    => "getSessionStorageKeys",
    "SetSessionStorageItem"    => "setSessionStorageItem",
    "ClearSessionStorage"      => "clearSessionStorage",
    "GetSessionStorageSize"    => "getSessionStorageSize",

    #
    # Mobile
    #
    "GetNetworkConnection" => "getNetworkConnection",
    "SetNetworkConnection" => "setNetworkConnection",
    "CurrentContextHandle" => "getCurrentContextHandle",
    "ContextHandles"       => "getContextHandles",
    "SwitchToContext"      => "switchToContext",

    #
    # Firefox
    #
    "GetContext"                              => "GET_CONTEXT",
    "SetContext"                              => "SET_CONTEXT",
    "ElementGetAnonymousChildren"             => "ELEMENT_GET_ANONYMOUS_CHILDREN",
    "ElementFindAnonymousElementsByAttribute" => "ELEMENT_FIND_ANONYMOUS_ELEMENTS_BY_ATTRIBUTE",
    "InstallAddon"                            => "INSTALL_ADDON",
    "UninstallAddon"                          => "UNINSTALL_ADDON",
    "FullPageScreenshot"                      => "FULL_PAGE_SCREENSHOT",

    #
    # Safari
    #
    "GetPermissions" => "GET_PERMISSIONS",
    "SetPermissions" => "SET_PERMISSIONS",
    "AttachDebugger" => "ATTACH_DEBUGGER",

    #
    # Chromium / Chrome
    #
    "LaunchApp"            => "launchApp",
    "SetNetworkConditions" => "setNetworkConditions",
    "GetNetworkConditions" => "getNetworkConditions",
    "ExecuteCdpCommand"    => "executeCdpCommand",
    "GetSinks"             => "getSinks",
    "GetIssueMessage"      => "getIssueMessage",
    "SetSinkToUse"         => "setSinkToUse",
    "StartTabMirroring"    => "startTabMirroring",
    "StopCasting"          => "stopCasting",

    #
    # Custom
    #
    "Pause" => "marionettePause",
  }

  SessionIdPath    = "/session/$sessionId"
  ElementId        = "$elementId"
  ElementIdPath    = "/element/" + ElementId
  WindowHandlePath = "/window/$windowHandle"
  NameTag          = "$name"

  BasicCommands = {
    "Status"                                 => {:get, "/status"},
    "NewSession"                             => {:post, "/session"},
    "GetAllSessions"                         => {:get, "/sessions"},
    "Quit"                                   => {:delete, SessionIdPath},
    "GetCurrentWindowHandle"                 => {:get, SessionIdPath + "/window_handle"},
    "W3CGetCurrentWindowHandle"              => {:get, SessionIdPath + "/window"},
    "GetWindowHandles"                       => {:get, SessionIdPath + "/window_handles"},
    "W3CGetWindowHandles"                    => {:get, SessionIdPath + "/window/handles"},
    "Get"                                    => {:post, SessionIdPath + "/url"},
    "GoForward"                              => {:post, SessionIdPath + "/forward"},
    "GoBack"                                 => {:post, SessionIdPath + "/back"},
    "Refresh"                                => {:post, SessionIdPath + "/refresh"},
    "ExecuteScript"                          => {:post, SessionIdPath + "/execute"},
    "W3CExecuteScript"                       => {:post, SessionIdPath + "/execute/sync"},
    "W3CExecuteScriptAsync"                  => {:post, SessionIdPath + "/execute/async"},
    "GetCurrentUrl"                          => {:get, SessionIdPath + "/url"},
    "GetTitle"                               => {:get, SessionIdPath + "/title"},
    "GetPageSource"                          => {:get, SessionIdPath + "/source"},
    "Screenshot"                             => {:get, SessionIdPath + "/screenshot"},
    "ElementScreenshot"                      => {:get, SessionIdPath + ElementIdPath + "/screenshot"},
    "FindElement"                            => {:post, SessionIdPath + "/element"},
    "FindElements"                           => {:post, SessionIdPath + "/elements"},
    "W3CGetActiveElement"                    => {:get, SessionIdPath + "/element/active"},
    "GetActiveElement"                       => {:post, SessionIdPath + "/element/active"},
    "GetElementShadowRoot"                   => {:get, SessionIdPath + ElementIdPath + "/shadow"},
    "FindChildElement"                       => {:post, SessionIdPath + ElementIdPath + "/element"},
    "FindChildElements"                      => {:post, SessionIdPath + ElementIdPath + "/elements"},
    "ClickElement"                           => {:post, SessionIdPath + ElementIdPath + "/click"},
    "ClearElement"                           => {:post, SessionIdPath + ElementIdPath + "/clear"},
    "SubmitElement"                          => {:post, SessionIdPath + ElementIdPath + "/submit"},
    "GetElementText"                         => {:get, SessionIdPath + ElementIdPath + "/text"},
    "SendKeysToElement"                      => {:post, SessionIdPath + ElementIdPath + "/value"},
    "SendKeysToActiveElement"                => {:post, SessionIdPath + "/keys"},
    "UploadFile"                             => {:post, SessionIdPath + "/file"},
    "GetElementValue"                        => {:get, SessionIdPath + ElementIdPath + "/value"},
    "GetElementTagName"                      => {:get, SessionIdPath + ElementIdPath + "/name"},
    "IsElementSelected"                      => {:get, SessionIdPath + ElementIdPath + "/selected"},
    "SetElementSelected"                     => {:post, SessionIdPath + ElementIdPath + "/selected"},
    "IsElementEnabled"                       => {:get, SessionIdPath + ElementIdPath + "/enabled"},
    "IsElementDisplayed"                     => {:get, SessionIdPath + ElementIdPath + "/displayed"},
    "GetElementLocation"                     => {:get, SessionIdPath + ElementIdPath + "/location"},
    "GetElementLocationOnceScrolledIntoView" => {:get, SessionIdPath + ElementIdPath + "/location_in_view"},
    "GetElementSize"                         => {:get, SessionIdPath + ElementIdPath + "/size"},
    "GetElementRect"                         => {:get, SessionIdPath + ElementIdPath + "/rect"},
    "GetElementAttribute"                    => {:get, SessionIdPath + ElementIdPath + "/attribute/" + NameTag},
    "GetElementProperty"                     => {:get, SessionIdPath + ElementIdPath + "/property/" + NameTag},
    "GetAllCookies"                          => {:get, SessionIdPath + "/cookie"},
    "AddCookie"                              => {:post, SessionIdPath + "/cookie"},
    "GetCookie"                              => {:get, SessionIdPath + "/cookie/" + NameTag},
    "DeleteAllCookies"                       => {:delete, SessionIdPath + "/cookie"},
    "DeleteCookie"                           => {:delete, SessionIdPath + "/cookie/" + NameTag},
    "SwitchToFrame"                          => {:post, SessionIdPath + "/frame"},
    "SwitchToParentFrame"                    => {:post, SessionIdPath + "/frame/parent"},
    "SwitchToWindow"                         => {:post, SessionIdPath + "/window"},
    "NewWindow"                              => {:post, SessionIdPath + "/window/new"},
    "Close"                                  => {:delete, SessionIdPath + "/window"},
    "GetElementValueOfCssProperty"           => {:get, SessionIdPath + ElementIdPath + "/css/" + NameTag},
    "ImplicitWait"                           => {:post, SessionIdPath + "/timeouts/implicit_wait"},
    "ExecuteAsyncScript"                     => {:post, SessionIdPath + "/execute_async"},
    "SetScriptTimeout"                       => {:post, SessionIdPath + "/timeouts/async_script"},
    "SetTimeouts"                            => {:post, SessionIdPath + "/timeouts"},
    "GetTimeouts"                            => {:get, SessionIdPath + "/timeouts"},
    "DismissAlert"                           => {:post, SessionIdPath + "/dismiss_alert"},
    "W3CDismissAlert"                        => {:post, SessionIdPath + "/alert/dismiss"},
    "AcceptAlert"                            => {:post, SessionIdPath + "/accept_alert"},
    "W3CAcceptAlert"                         => {:post, SessionIdPath + "/alert/accept"},
    "SetAlertValue"                          => {:post, SessionIdPath + "/alert_text"},
    "W3CSetAlertValue"                       => {:post, SessionIdPath + "/alert/text"},
    "GetAlertText"                           => {:get, SessionIdPath + "/alert_text"},
    "W3CGetAlertText"                        => {:get, SessionIdPath + "/alert/text"},
    "SetAlertCredentials"                    => {:post, SessionIdPath + "/alert/credentials"},
    "Click"                                  => {:post, SessionIdPath + "/click"},
    "W3CActions"                             => {:post, SessionIdPath + "/actions"},
    "W3CClearActions"                        => {:delete, SessionIdPath + "/actions"},
    "DoubleClick"                            => {:post, SessionIdPath + "/doubleclick"},
    "MouseDown"                              => {:post, SessionIdPath + "/buttondown"},
    "MouseUp"                                => {:post, SessionIdPath + "/buttonup"},
    "MoveTo"                                 => {:post, SessionIdPath + "/moveto"},
    "GetWindowSize"                          => {:get, SessionIdPath + WindowHandlePath + "/size"},
    "SetWindowSize"                          => {:post, SessionIdPath + WindowHandlePath + "/size"},
    "GetWindowPosition"                      => {:get, SessionIdPath + WindowHandlePath + "/position"},
    "SetWindowPosition"                      => {:post, SessionIdPath + WindowHandlePath + "/position"},
    "SetWindowRect"                          => {:post, SessionIdPath + "/window/rect"},
    "GetWindowRect"                          => {:get, SessionIdPath + "/window/rect"},
    "MaximizeWindow"                         => {:post, SessionIdPath + WindowHandlePath + "/maximize"},
    "W3CMaximizeWindow"                      => {:post, SessionIdPath + "/window/maximize"},
    "SetScreenOrientation"                   => {:post, SessionIdPath + "/orientation"},
    "GetScreenOrientation"                   => {:get, SessionIdPath + "/orientation"},
    "SingleTap"                              => {:post, SessionIdPath + "/touch/click"},
    "TouchDown"                              => {:post, SessionIdPath + "/touch/down"},
    "TouchUp"                                => {:post, SessionIdPath + "/touch/up"},
    "TouchMove"                              => {:post, SessionIdPath + "/touch/move"},
    "TouchScroll"                            => {:post, SessionIdPath + "/touch/scroll"},
    "DoubleTap"                              => {:post, SessionIdPath + "/touch/doubleclick"},
    "LongPress"                              => {:post, SessionIdPath + "/touch/longclick"},
    "Flick"                                  => {:post, SessionIdPath + "/touch/flick"},
    "ExecuteSql"                             => {:post, SessionIdPath + "/execute_sql"},
    "GetLocation"                            => {:get, SessionIdPath + "/location"},
    "SetLocation"                            => {:post, SessionIdPath + "/location"},
    "GetAppCache"                            => {:get, SessionIdPath + "/application_cache"},
    "GetAppCacheStatus"                      => {:get, SessionIdPath + "/application_cache/status"},
    "ClearAppCache"                          => {:delete, SessionIdPath + "/application_cache/clear"},
    "GetNetworkConnection"                   => {:get, SessionIdPath + "/network_connection"},
    "SetNetworkConnection"                   => {:post, SessionIdPath + "/network_connection"},
    "GetLocalStorageItem"                    => {:get, SessionIdPath + "/local_storage/key/" + NameTag},
    "RemoveLocalStorageItem"                 => {:delete, SessionIdPath + "/local_storage/key/" + NameTag},
    "GetLocalStorageKeys"                    => {:get, SessionIdPath + "/local_storage"},
    "SetLocalStorageItem"                    => {:post, SessionIdPath + "/local_storage"},
    "ClearLocalStorage"                      => {:delete, SessionIdPath + "/local_storage"},
    "GetLocalStorageSize"                    => {:get, SessionIdPath + "/local_storage/size"},
    "GetSessionStorageItem"                  => {:get, SessionIdPath + "/session_storage/key/" + NameTag},
    "RemoveSessionStorageItem"               => {:delete, SessionIdPath + "/session_storage/key/" + NameTag},
    "GetSessionStorageKeys"                  => {:get, SessionIdPath + "/session_storage"},
    "SetSessionStorageItem"                  => {:post, SessionIdPath + "/session_storage"},
    "ClearSessionStorage"                    => {:delete, SessionIdPath + "/session_storage"},
    "GetSessionStorageSize"                  => {:get, SessionIdPath + "/session_storage/size"},
    "GetLog"                                 => {:post, SessionIdPath + "/se/log"},
    "GetAvailableLogTypes"                   => {:get, SessionIdPath + "/se/log/types"},
    "CurrentContextHandle"                   => {:get, SessionIdPath + "/context"},
    "ContextHandles"                         => {:get, SessionIdPath + "/contexts"},
    "SwitchToContext"                        => {:post, SessionIdPath + "/context"},
    "FullscreenWindow"                       => {:post, SessionIdPath + "/window/fullscreen"},
    "MinimizeWindow"                         => {:post, SessionIdPath + "/window/minimize"},
  }

  FirefoxCommands = BasicCommands.merge({
    "GetContext"                              => {:get, SessionIdPath + "/moz/context"},
    "SetContext"                              => {:post, SessionIdPath + "/moz/context"},
    "ElementGetAnonymousChildren"             => {:post, SessionIdPath + "/moz/xbl/" + ElementId + "/anonymous_children"},
    "ElementFindAnonymousElementsByAttribute" => {:post, SessionIdPath + "/moz/xbl/" + ElementId + "/anonymous_by_attribute"},
    "InstallAddon"                            => {:post, SessionIdPath + "/moz/addon/install"},
    "UninstallAddon"                          => {:post, SessionIdPath + "/moz/addon/uninstall"},
    "FullPageScreenshot"                      => {:get, SessionIdPath + "/moz/screenshot/full"},
  })

  SafariCommands = BasicCommands.merge({
    "GetPermissions" => {:get, SessionIdPath + "/apple/permissions"},
    "SetPermissions" => {:post, SessionIdPath + "/apple/permissions"},
    "AttachDebugger" => {:post, SessionIdPath + "/apple/attach_debugger"},
  })

  ChromiumCommands = BasicCommands.merge({
    "LaunchApp"            => {:post, SessionIdPath + "/chromium/launch_app"},
    "SetNetworkConditions" => {:post, SessionIdPath + "/chromium/network_conditions"},
    "GetNetworkConditions" => {:get, SessionIdPath + "/chromium/network_conditions"},
    "ExecuteCdpCommand"    => {:post, SessionIdPath + "/goog/cdp/execute"},
    "GetSinks"             => {:get, SessionIdPath + "/goog/cast/get_sinks"},
    "GetIssueMessage"      => {:get, SessionIdPath + "/goog/cast/get_issue_message"},
    "SetSinkToUse"         => {:post, SessionIdPath + "/goog/cast/set_sink_to_use"},
    "StartTabMirroring"    => {:post, SessionIdPath + "/goog/cast/start_tab_mirroring"},
    "StopCasting"          => {:post, SessionIdPath + "/goog/cast/stop_casting"},
  })
end
