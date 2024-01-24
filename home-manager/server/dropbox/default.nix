{ lib, pkgs, ... }:

{
	# TODO: switch to Maestral, as this doesn't work
	systemd.user.services.dropbox = {
		Unit = {
			Description = "Dropbox";
			After = [ "graphical-session-pre.target" ];
			PartOf = [ "graphical-session.target" ];
		};

		Service = {
			Restart = "on-failure";
			RestartSec = 1;
			ExecStart = "${lib.getBin pkgs.dropbox}/bin/dropbox";
			ExecReload = "${lib.getBin pkgs.coreutils}/bin/kill -HUP $MAINPID";
			Environment = [
				("QT_PLUGIN_PATH=/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix)
				("QML2_IMPORT_PATH=/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix)
			];
		};

		Install = {
			WantedBy = [ "graphical-session.target" ];
		};
	};
}
