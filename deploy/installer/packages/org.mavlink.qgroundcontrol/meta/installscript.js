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
        component.addOperation("CreateShortcut", "@TargetDir@/bin/AMC.exe", "@StartMenuDir@/AMC.lnk");
        component.addOperation("CreateShortcut", "@TargetDir@/bin/AMC.exe", "@DesktopDir@/AMC.lnk");
    }
}
