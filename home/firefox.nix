# firefox.nix -- librefos's Firefox profile.  The browser itself and
# the enterprise policies are in modules/firefox.nix, which is why
# package is null here.
#
# dev-edition-default is the profile name Developer Edition uses.
# home-manager writes profiles.ini without [Install...] sections, which
# is enough: the nixpkgs wrapper sets MOZ_LEGACY_PROFILES=1, so Firefox
# takes the profile marked Default=1, which id 0 is.  At this
# home.stateVersion the profile goes in ~/.config/mozilla/firefox, not
# ~/.mozilla/firefox.  (home-manager, programs/firefox/)

{
  programs.firefox = {
    enable = true;
    package = null;

    profiles.dev-edition-default = {
      id = 0;

      settings = {
        # Profile & UI
        "browser.aboutConfig.showWarning" = false;
        "ui.systemUsesDarkTheme" = 1;
        "browser.in-content.dark-mode" = true;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
        # Nova is the redesign Firefox turns on by default from 158; it
        # restyles every theme, dark included, and gives the selected
        # tab a violet-to-orange gradient border.  Off, the compact dark
        # theme is plain dark again.
        "browser.nova.enabled" = false;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.uidensity" = 1;
        "browser.uiCustomization.state" = "{\"placements\":{\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"spring\",\"vertical-spacer\",\"urlbar-container\",\"spring\",\"ublock0_raymondhill_net-browser-action\",\"downloads-button\",\"open-file-button\",\"profiler-button\",\"panic-button\",\"library-button\",\"preferences-button\",\"developer-button\"]},\"seen\":[\"ublock0_raymondhill_net-browser-action\",\"developer-button\",\"library-button\",\"open-file-button\",\"panic-button\",\"preferences-button\",\"profiler-button\"],\"dirtyAreaCache\":[\"nav-bar\"],\"currentVersion\":24,\"newElementCount\":0}";
        "browser.toolbars.bookmarks.visibility" = "never";

        # Home & Startup
        "browser.startup.page" = 0;
        "browser.startup.homepage" = "about:blank";
        "browser.startup.homepage.abouthome_cache.enabled" = false;
        "browser.newtabpage.enabled" = false;
        "browser.newtab.preload" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # Search & Address Bar
        "browser.search.suggest.enabled" = false;
        "browser.search.suggest.enabled.private" = false;
        "browser.urlbar.suggest.history" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.recentsearches" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.quickactions" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.remotetab" = false;
        "browser.urlbar.suggest.calculator" = false;
        "browser.urlbar.suggest.weather" = false;
        "browser.urlbar.suggest.trending" = false;
        "browser.urlbar.suggest.quicksuggest.all" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.quicksuggest.online.enabled" = false;
        "browser.urlbar.quicksuggest.mlEnabled" = false;
        "browser.urlbar.suggest.addons" = false;
        "browser.urlbar.suggest.mdn" = false;
        "browser.urlbar.suggest.yelp" = false;
        "browser.urlbar.suggest.amp" = false;
        "browser.urlbar.suggest.wikipedia" = false;
        "browser.urlbar.wikipedia.featureGate" = false;
        "browser.urlbar.suggest.sports" = false;
        "browser.urlbar.showSearchTerms.enabled" = false;
        "browser.urlbar.showSearchTerms.featureGate" = false;

        # Privacy & Security
        "browser.contentblocking.category" = "strict";
        "browser.contentblocking.features.strict" = "tp,tpPrivate,cookieBehavior5,cookieBehaviorPBM5,cryptoTP,fp,stp,emailTP,emailTPPrivate,-consentmanagerSkip,-consentmanagerSkipPrivate,lvl2,rp,rpTop,qps,qpsPBM,fpp,fppPrivate,btp,lna";
        "network.cookie.cookieBehavior" = 5;
        "network.cookie.cookieBehavior.pbmode" = 5;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.pbmode.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.globalprivacycontrol.pbmode.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.sanitize.sanitizeOnShutdown" = true;
        "places.history.enabled" = false;
        "browser.formfill.enable" = false;
        "privacy.clearOnShutdown.history" = true;
        "privacy.clearOnShutdown.downloads" = true;
        "privacy.clearOnShutdown.formdata" = false;
        "privacy.clearOnShutdown.cookies" = true;
        "privacy.clearOnShutdown.cache" = true;
        "privacy.clearOnShutdown.sessions" = true;
        "privacy.clearOnShutdown.offlineApps" = true;
        "privacy.clearOnShutdown.siteSettings" = true;
        "privacy.clearOnShutdown.openWindows" = false;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
        "privacy.clearOnShutdown_v2.cache" = true;
        "privacy.clearOnShutdown_v2.siteSettings" = true;
        "privacy.clearOnShutdown_v2.formdata" = false;
        "privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs2" = true;
        "privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs3" = true;
        "network.trr.mode" = 3;
        "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
        "network.trr.custom_uri" = "https://mozilla.cloudflare-dns.com/dns-query";
        "network.trr_ui.fallback_was_checked" = true;
        "doh-rollout.mode" = 3;
        "doh-rollout.disable-heuristics" = true;
        "doh-rollout.clearModeOnShutdown" = false;
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_pbm" = true;
        "dom.security.https_only_mode_ever_enabled" = true;
        "dom.security.https_only_mode_ever_enabled_pbm" = true;

        # Passwords & Autofill
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.addresses.capture.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;

        # Downloads
        "browser.download.folderList" = 2;
        "browser.download.dir" = "/tmp";
        "browser.download.useDownloadDir" = false;
        "browser.download.always_ask_before_handling_new_types" = true;
        "browser.download.enableDeletePrivate" = true;
        "browser.download.deletePrivate" = true;
        "browser.download.deletePrivate.chosen" = true;

        # Linux Integration
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.eme.enabled" = true;

        # Tabs & Browsing
        # Firefox's own horizontal strip at the top, left as it ships;
        # there is no userChrome.css, so nothing restyles them.
        "sidebar.verticalTabs" = false;
        # hide-sidebar, so the launcher strip of tool icons is not down
        # the side of every window; the sidebar button in the nav bar
        # still opens it.  The other values are always-show and
        # expand-on-hover, which was what left the strip there.
        "sidebar.visibility" = "hide-sidebar";
        "sidebar.expandOnHover" = false;
        "sidebar.revamp" = true;
        "sidebar.main.tools" = "syncedtabs,history";
        "browser.ctrlTab.sortByRecentlyUsed" = false;
        "browser.tabs.hoverPreview.enabled" = false;
        "browser.tabs.hoverPreview.showThumbnails" = false;
        "browser.tabs.groups.hoverPreview.enabled" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "browser.tabs.groups.smart.userEnabled" = false;
        "browser.tabs.groups.smart.optin" = false;
        "browser.ml.linkPreview.enabled" = false;
        "browser.ml.linkPreview.optin" = false;
        "media.videocontrols.picture-in-picture.enabled" = false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
        "media.videocontrols.picture-in-picture.urlbar-button.enabled" = false;

        # Recommendations, Language & AI
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "browser.discovery.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.translations.enable" = false;
        "browser.translations.select.enable" = false;
        "browser.translations.quickAction.enabled" = false;
        "browser.translations.automaticallyPopup" = false;
        "intl.accept_languages" = "en";
        "intl.locale.requested" = "en";
        "layout.spellcheckDefault" = 0;
        "browser.ai.control.default" = "blocked";
        "browser.ai.control.translations" = "blocked";
        "browser.ai.control.smartTabGroups" = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.sidebarChatbot" = "blocked";
        "browser.ai.control.smartWindow" = "blocked";

        # Permissions
        "permissions.default.geo" = 2;
        "permissions.default.camera" = 2;
        "permissions.default.microphone" = 2;
        "permissions.default.desktop-notification" = 2;
        "permissions.default.xr" = 2;
        "permissions.default.local-network" = 2;
        "permissions.default.loopback-network" = 2;
        "network.lna.blocking" = true;
        "media.setsinkid.enabled" = false;

        # Developer Tools
        "devtools.theme" = "dark";
        "devtools.toolbox.host" = "right";
        "devtools.cache.disabled" = true;
        "devtools.inspector.showUserAgentStyles" = true;
        "devtools.performance.popup.feature-flag" = true;
        "devtools.command-button-frames.enabled" = true;
        "devtools.command-button-responsive.enabled" = true;
        "devtools.command-button-screenshot.enabled" = true;
        "devtools.command-button-rulers.enabled" = true;
        "devtools.command-button-measure.enabled" = true;
        "devtools.command-button-noautohide.enabled" = true;
        "devtools.command-button-paintflashing.enabled" = true;
        "devtools.webconsole.persistlog" = true;
        "devtools.netmonitor.persistlog" = true;
        "devtools.webconsole.timestampMessages" = true;

        # Browser Toolbox / Browser Console support. Keep the connection prompt on.
        "devtools.chrome.enabled" = true;
        "devtools.debugger.remote-enabled" = true;
        "devtools.debugger.prompt-connection" = true;
      };
    };
  };
}
