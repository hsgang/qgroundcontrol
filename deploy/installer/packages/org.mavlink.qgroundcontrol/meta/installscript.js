function Component()
{

}

Component.prototype.createOperations = function()
{
    try {
        component.createOperations();
    } catch (e) {
        console.log(e);
    }

    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/bin/missionnavigator.exe", "@StartMenuDir@/MissionNavigator.lnk");
        component.addOperation("CreateShortcut", "@TargetDir@/bin/missionnavigator.exe", "@DesktopDir@/MissionNavigator.lnk");
    }
}
