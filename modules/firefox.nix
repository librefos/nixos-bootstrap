# firefox.nix -- Firefox Developer Edition, and the enterprise policies
# every profile starts from.  The profile itself, librefos's
# preferences and stylesheet, is in home/firefox.nix.

{ pkgs, ... }:

{
  # Developer Edition is built from Mozilla's source like the release
  # and is not excluded from the build farm, so it comes from the binary
  # cache rather than compiling here; scripts/apply.sh's dry build says
  # which before anything happens.  The module writes the policies below
  # to /etc/firefox/policies/policies.json and adds DisableAppUpdate of
  # its own.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    policies = {
      AIControls = {
        Default = {
          Value = "blocked";
          Locked = true;
        };
        Translations = {
          Value = "blocked";
          Locked = true;
        };
        PDFAltText = {
          Value = "blocked";
          Locked = true;
        };
        SmartTabGroups = {
          Value = "blocked";
          Locked = true;
        };
        LinkPreviewKeyPoints = {
          Value = "blocked";
          Locked = true;
        };
        SidebarChatbot = {
          Value = "blocked";
          Locked = true;
        };
        SmartWindow = {
          Value = "blocked";
          Locked = true;
        };
      };
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      Cookies = {
        # One permission per origin, so a subdomain is a separate entry
        # rather than another spelling of the same site.  The policy
        # adds these with EXPIRE_POLICY, which is never written to
        # permissions.sqlite, so this list is the whole of the profile's
        # cookie exceptions and dropping an entry drops the exception.
        Allow = [
          "https://github.com"
          "https://google.com"
        ];
        ExpireAtSessionEnd = true;
        Behavior = "reject-tracker-and-partition-foreign";
        BehaviorPrivateBrowsing = "reject-tracker-and-partition-foreign";
      };
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Fallback = false;
      };
      DefaultDownloadDirectory = "/tmp";
      DownloadDirectory = "/tmp";
      EnableTrackingProtection = {
        Value = true;
        Category = "strict";
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      # uBlock Origin, installed from AMO on the first run of a new
      # profile and kept there: force_installed cannot be removed or
      # disabled from about:addons.  Its button is placed in the nav bar
      # by browser.uiCustomization.state, here and in home/firefox.nix,
      # since that pref is rewritten on every start and would otherwise
      # drop it into the hidden extensions menu.
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          private_browsing = true;
          default_area = "navbar";
        };
      };
      EncryptedMediaExtensions = {
        Enabled = true;
      };
      Homepage = {
        URL = "about:blank";
        StartPage = "none";
      };
      HttpsOnlyMode = "enabled";
      NewTabPage = false;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      Permissions = {
        Camera = {
          BlockNewRequests = true;
          Locked = false;
        };
        Location = {
          BlockNewRequests = true;
          Locked = false;
        };
        Microphone = {
          BlockNewRequests = true;
          Locked = false;
        };
        Notifications = {
          BlockNewRequests = true;
          Locked = false;
        };
        VirtualReality = {
          BlockNewRequests = true;
          Locked = false;
        };
      };
      Preferences = {
        "browser.ctrlTab.sortByRecentlyUsed" = {
          Value = false;
          Status = "default";
        };
        "browser.download.deletePrivate" = {
          Value = true;
          Status = "default";
        };
        "browser.download.enableDeletePrivate" = {
          Value = true;
          Status = "default";
        };
        "browser.ml.linkPreview.enabled" = {
          Value = false;
          Status = "default";
        };
        "browser.tabs.groups.smart.userEnabled" = {
          Value = false;
          Status = "default";
        };
        "browser.nova.enabled" = {
          Value = false;
          Status = "default";
        };
        "browser.toolbars.bookmarks.visibility" = {
          Value = "never";
          Status = "default";
        };
        "browser.uiCustomization.state" = {
          Value = "{\"placements\":{\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"spring\",\"vertical-spacer\",\"urlbar-container\",\"spring\",\"ublock0_raymondhill_net-browser-action\",\"downloads-button\",\"open-file-button\",\"profiler-button\",\"panic-button\",\"library-button\",\"preferences-button\",\"developer-button\"]},\"seen\":[\"ublock0_raymondhill_net-browser-action\",\"developer-button\",\"library-button\",\"open-file-button\",\"panic-button\",\"preferences-button\",\"profiler-button\"],\"dirtyAreaCache\":[\"nav-bar\"],\"currentVersion\":24,\"newElementCount\":0}";
          Status = "default";
        };
        "browser.urlbar.showSearchTerms.enabled" = {
          Value = false;
          Status = "default";
        };
        "browser.urlbar.showSearchTerms.featureGate" = {
          Value = false;
          Status = "default";
        };
        "browser.urlbar.suggest.quickactions" = {
          Value = false;
          Status = "default";
        };
        "browser.urlbar.suggest.wikipedia" = {
          Value = false;
          Status = "default";
        };
        "browser.urlbar.wikipedia.featureGate" = {
          Value = false;
          Status = "default";
        };
        "devtools.cache.disabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.chrome.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-frames.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-measure.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-noautohide.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-paintflashing.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-responsive.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-rulers.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.command-button-screenshot.enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.debugger.prompt-connection" = {
          Value = true;
          Status = "default";
        };
        "devtools.debugger.remote-enabled" = {
          Value = true;
          Status = "default";
        };
        "devtools.inspector.showUserAgentStyles" = {
          Value = true;
          Status = "default";
        };
        "devtools.netmonitor.persistlog" = {
          Value = true;
          Status = "default";
        };
        "devtools.performance.popup.feature-flag" = {
          Value = true;
          Status = "default";
        };
        "devtools.theme" = {
          Value = "dark";
          Status = "default";
        };
        "devtools.toolbox.host" = {
          Value = "right";
          Status = "default";
        };
        "devtools.webconsole.persistlog" = {
          Value = true;
          Status = "default";
        };
        "devtools.webconsole.timestampMessages" = {
          Value = true;
          Status = "default";
        };
        "intl.accept_languages" = {
          Value = "en";
          Status = "default";
        };
        "intl.locale.requested" = {
          Value = "en";
          Status = "default";
        };
        "layout.spellcheckDefault" = {
          Value = 0;
          Status = "default";
        };
        "network.lna.blocking" = {
          Value = true;
          Status = "default";
        };
        "permissions.default.local-network" = {
          Value = 2;
          Status = "default";
        };
        "permissions.default.loopback-network" = {
          Value = 2;
          Status = "default";
        };
        "places.history.enabled" = {
          Value = false;
          Status = "default";
        };
        "privacy.globalprivacycontrol.enabled" = {
          Value = true;
          Status = "default";
        };
        "privacy.panicButton.enabled" = {
          Value = true;
          Status = "default";
        };
      };
      PromptForDownloadLocation = true;
      RequestedLocales = [
        "en"
      ];
      SearchEngines = {
        Add = [
          {
            Name = "Lite DuckDuckGo";
            Alias = "@lddg";
            URLTemplate = "https://lite.duckduckgo.com/lite/search?q={searchTerms}";
            Method = "GET";
          }
        ];
        Default = "Lite DuckDuckGo";
        DefaultPrivate = "Lite DuckDuckGo";
        PreventInstalls = true;
        # Display names, matched exactly, so a near miss removes nothing
        # and reports nothing.  Wikipedia carries its locale in the name.
        Remove = [
          "Google"
          "DuckDuckGo"
          "Bing"
          "Perplexity"
          "Wikipedia (en)"
        ];
      };
      SearchSuggestEnabled = false;
    };
  };
}
