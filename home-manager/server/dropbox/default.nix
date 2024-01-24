{ pkgs, ... }:

{
	systemd.user.services.dropbox = {
		Description = "Dropbox";
		WantedBy = [ "graphical-session.target" ];
		Environment = {
			QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
			QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
		};
		ServiceConfig = {
			ExecStart = "${lib.getBin pkgs.dropbox}/bin/dropbox";
			ExecReload = "${lib.getBin pkgs.coreutils}/bin/kill -HUP $MAINPID";
			KillMode = "control-group"; # upstream recommends process
				Restart = "on-failure";
			PrivateTmp = true;
			ProtectSystem = "full";
			Nice = 10;
		};
	};
}
