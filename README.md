# What Is DCS2TARGET?

Out of the box, the Thrustmaster Viper Mission Pack and Viper Panel landing gear and other indicators are not functional and are not integrated with DCS or Falcon BMS. This isn't a fault of the product or Thrustmaster as there are far too many applications, each with their unique style of exposing simulation data. It isn't fair to expect Thrustmaster to support all of those applications and this is where the community fills the gap.

Along with dcs2target, you will also need [TMHotasLEDSync](https://github.com/iknowkungfutoo/TMHotasLEDSync). Together, they enable the LEDs on the Viper Mission Pack, Viper Panel, and Warthog to relay the indicators in the DCS cockpits. There is a caveat, though, as I will explain below.

For the Viper Mission Pack and Viper Panel, some LEDs can be used to relay the indicators of the F-16 landing gear, the landing gear handle and the threat warning auxiliary panel. It also has two columns of five user-programmable LEDs. However, the LEDs in the threat warning auxiliary switches do not fully mimic those of the real aircraft. Specifically, the "altitude" switch can either be illuminated red or green on the Viper Mission Pack / Panel as opposed to "LOW" in amber and "ALT" in green. Also, the ACT/PWR switch has only one physical LED for what are two separate real-aircraft states, so it is lit solid for POWER and flashes to indicate activity, rather than showing both independently. Therefore, we have to accept some compromises regarding how the indicators of the F-16 can be shown on the Viper Mission Pack / Panel.

For the Warthog, there is only a column of five LEDs for the user to configure.

# How It Works:

DCS2Target is a set of lua files that interrogate DCS and send the relevant lamp data to the Thrustmaster TARGET software running the TMHotasLEDSync.tmc script. Data is sent via TCP only if the simulation data changes. The TARGET script handles each packet through an event, so it is fairly efficient and should not introduce any significant load on your CPU.

The DCS simulation data is interrogated every 100ms (that’s ten times a second). It’s not too taxing on the system yet fast enough so that we humans shouldn’t notice any lag.

The TARGET script does not configure your HOTAS throttle for use with DCS. It merely controls the LEDs of the HOTAS throttle. If you use another TARGET script to map your device to DCS, I advise you to use DCS to map the axis, buttons and switches instead. However, if you wish to use a TARGET script to map your HOTAS throttle to DCS, you’ll have to try to figure out how to combine this script with yours. Please don’t ask me to help combine scripts; you’ll have to figure that out yourself.

# Installation:

Run `dcs2target.msi`. It detects which of your DCS Saved Games folders (Stable and/or Open Beta) already exist and installs into those by default, with checkboxes to add or remove either one. Uninstalling via Windows' "Apps & Features" removes everything it installed.

The installer only supports the two standard folder names (`DCS` and `DCS.openbeta`). If you use a `dcs_variant.txt`-renamed Saved Games folder, run the installer with Stable or Open Beta checked and then manually copy the resulting `Hooks` and `dcs2target` folders from that Saved Games location into your custom one.

Install [TMHotasLEDSync](https://github.com/iknowkungfutoo/TMHotasLEDSync) using its MSI installer. This creates a "Thrustmaster HOTAS LED Sync" shortcut in a "Slughead Products" Start Menu folder that automatically starts the Thrustmaster T.A.R.G.E.T. software with the TMHotasLEDSync.tmc script loaded and running.

# How To Use:

1. Run the "Thrustmaster HOTAS LED Sync" shortcut created by its installer (Start Menu > Slughead Products, or the Desktop if you chose that option).
2. Start DCS.

# Supported Aircraft:

The following aircraft are currently supported:

| AIRCRAFT | EXPORTED PARAMETERS |
|------------|-----------------------------------------------------------------|
| A-10C | Speed brake position, gear warning, cockpit unlocked, console lighting, Master Caution, Anti Skid, Inverter and Fire Warning status. |
| A-10C_2 | Speed brake position, gear warning, cockpit unlocked, console lighting, Master Caution, Anti Skid, Inverter and Fire Warning status. |
| F-16 | Gear, gear warning, TWA indications, JFS RUN, MAIN GEN, STBY GEN, FLCS RLY, EPU RUN and the speed brake position. |
| FA-18_Hornet | Speed brake position, console lighting, APU RUN, Gear Handle lamp, Master Caution, Wing Fold, Launch Bar and Arresting Hook status. |
| JF-17 | Gear, gear warning, gear transit, master warning and the speed brake position. |

# Suggestions And Feature Requests:

Feel free to make any suggestions for improvements on [dcs2target DCS thread](https://forum.dcs.world/topic/338119-dcs2target-dcs-to-thrustmaster-hotas-led-controller-viper-mission-pack-viper-panel-and-warthog/#comments) or [here](https://github.com/iknowkungfutoo/DCS2Target/discussions).

# Need Help?

Raise an issue on the [dcs2target DCS thread](https://forum.dcs.world/topic/338119-dcs2target-dcs-to-thrustmaster-hotas-led-controller-viper-mission-pack-viper-panel-and-warthog/#comments) or [here](https://github.com/iknowkungfutoo/DCS2Target/issues). Include your dcs.log and TARGET script editor console output in your message (you can select all using CTRL-A, copy using CTRL-C and paste with CTRL-V directly from the TARGET console output using your mouse).


