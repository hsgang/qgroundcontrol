import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs              1.3

import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    id: rootWindow
    color: "#394454"

    Rectangle{
        id : loginRect
        anchors.centerIn: parent
        width: rootWindow.width * 0.25
        height: rootWindow.height * 0.3

        ColumnLayout {
            id: loginColumnLt
            //spacing: 5
            Layout.alignment: Qt.AlignVCenter
            //anchors.horizontalCenter: parent.horizontalCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 20
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 20
            anchors.fill: parent

            Rectangle{
                //color: "red"
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: loginRect.height * 0.5
                Layout.preferredWidth: loginRect.width * 0.8
                Image {
                    id: logoimage
                    height: parent.height * 0.5
                    fillMode: Image.PreserveAspectFit
                    source: "/res/QGCLogoFull"
                    anchors.centerIn: parent
                }
            }
            Rectangle{
                //color:"blue"
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: loginRect.height * 0.2
                Layout.preferredWidth: loginRect.width * 0.8
                GridLayout {
                    anchors.centerIn: parent
                    Layout.fillWidth: true
                    columnSpacing: 20
                    rowSpacing: 4
                    columns: 2

                    Text { text: "Username: "; Layout.fillWidth:true; }
                    TextField { id:usernameText; placeholderText: "username"; Layout.fillWidth: true;}
                    Text { text: "Password:";Layout.fillWidth:true }
                    TextField { id:passwordText; placeholderText: "password"; echoMode: TextInput.Password; Layout.fillWidth: true;}
                }
            }

            Rectangle{
                //color:"yellow"
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: loginRect.height * 0.2
                Layout.preferredWidth: loginRect.width * 0.8
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    spacing: 20
                    Button { text: "Login"; onClicked: {
                            //console.log(usernameText.text,passwordText.text);
                            if(usernameText.text === "admin" && passwordText.text === "password"){
                                rootWindow.visible = false;
                                mainWindow.header.visible = true;
                            }
                            else{
                                console.log(usernameText.text,passwordText.text);
                            };

                            //passwordText.enabled=false;
                            //usernameText.enabled=false;
                            //auth_controller.sayHello();
                            //mojoRootViewHolder.source="Welcome.qml"
                        }
                    }
                    //Button { text: "Exit"; onClicked: rootWindow.visible = false }
                    //Button { text: "Exit"; onClicked: mainWindow.header.visible = false }
                }
            }
        }
    }

    // After loading show initial Login Page
//    Component.onCompleted: {
//        stackView.push("qrc:/qml/LoginDialogLoginPage.qml")   //initial page
//        //dataBase = userDataBase()
//        console.log(dataBase.version)
//    }

    //Popup to show messages or warnings on the bottom postion of the screen
//    Popup {
//        id: popup
//        property alias popMessage: message.text

//        background: Rectangle {
//            implicitWidth: rootWindow.width
//            implicitHeight: 60
//            color: popupBackGroundColor
//        }
//        y: (rootWindow.height - 60)
//        modal: true
//        focus: true
//        closePolicy: Popup.CloseOnPressOutside
//        Text {
//            id: message
//            anchors.centerIn: parent
//            font.pointSize: 12
//            color: popupTextCOlor
//        }
//        onOpened: popupClose.start()
//    }

    // Popup will be closed automatically in 2 seconds after its opened
    Timer {
        id: popupClose
        interval: 2000
        onTriggered: popup.close()
    }

    // Create and initialize the database
//    function userDataBase()
//    {
//        var db = LocalStorage.openDatabaseSync("UserLoginApp", "1.0", "Login example!", 1000000);
//        db.transaction(function(tx) {
//            tx.executeSql('CREATE TABLE IF NOT EXISTS UserDetails(username TEXT, password TEXT, hint TEXT)');
//        })

//        return db;
//    }

    // Register New user
//    function registerNewUser(uname, pword, pword2, hint)
//    {
//        var ret  = Backend.validateRegisterCredentials(uname, pword, pword2, hint)
//        var message = ""
//        switch(ret)
//        {
//        case 0: message = "Valid details!"
//            break;
//        case 1: message = "Missing credentials!"
//            break;
//        case 2: message = "Password does not match!"
//            break;
//        }

//        if(0 !== ret)
//        {
//            popup.popMessage = message
//            popup.open()
//            return
//        }

//        dataBase.transaction(function(tx) {
//            var results = tx.executeSql('SELECT password FROM UserDetails WHERE username=?;', uname);
//            console.log(results.rows.length)
//            if(results.rows.length !== 0)
//            {
//                popup.popMessage = "User already exist!"
//                popup.open()
//                return
//            }
//            tx.executeSql('INSERT INTO UserDetails VALUES(?, ?, ?)', [ uname, pword, hint ]);
//            showUserInfo(uname) // goto user info page
//        })
//    }

    // Login users
//    function loginUser(uname, pword)
//    {
//        var ret  = Backend.validateUserCredentials(uname, pword)
//        var message = ""
//        if(ret)
//        {
//            message = "Missing credentials!"
//            popup.popMessage = message
//            popup.open()
//            return
//        }

//        dataBase.transaction(function(tx) {
//            var results = tx.executeSql('SELECT password FROM UserDetails WHERE username=?;', uname);
//            if(results.rows.length === 0)
//            {
//                message = "User not registered!"
//                popup.popMessage = message
//                popup.open()
//            }
//            else if(results.rows.item(0).password !== pword)
//            {
//                message = "Invalid credentials!"
//                popup.popMessage = message
//                popup.open()
//            }
//            else
//            {
//                console.log("Login Success!")
//                showUserInfo(uname)
//            }
//        })
//    }

    // Retrieve password using password hint
//    function retrievePassword(uname, phint)
//    {
//        var ret  = Backend.validateUserCredentials(uname, phint)
//        var message = ""
//        var pword = ""
//        if(ret)
//        {
//            message = "Missing credentials!"
//            popup.popMessage = message
//            popup.open()
//            return ""
//        }

//        console.log(uname, phint)
//        dataBase.transaction(function(tx) {
//            var results = tx.executeSql('SELECT password FROM UserDetails WHERE username=? AND hint=?;', [uname, phint]);
//            if(results.rows.length === 0)
//            {
//                message = "User not found!"
//                popup.popMessage = message
//                popup.open()
//            }
//            else
//            {
//                pword = results.rows.item(0).password
//            }
//        })
//        return pword
//    }


    // Show UserInfo page
//    function showUserInfo(uname)
//    {
//        stackView.replace("qrc:/qml/LoginDialogUserInfoPage.qml", {"userName": uname})
//    }

//    // Logout and show login page
//    function logoutSession()
//    {
//        stackView.replace("qrc:/qml/LoginDialogLogInPage.qml")
//    }

//    // Show Password reset page
//    function forgotPassword()
//    {
//        stackView.replace("qrc:/qml/LoginDialogPasswordResetPage.qml")
//    }

    // Show all users
//    function showAllUsers()
//    {
//        dataBase.transaction(function(tx) {
//            var rs = tx.executeSql('SELECT * FROM UserDetails');
//            var data = ""
//            for(var i = 0; i < rs.rows.length; i++) {
//                data += rs.rows.item(i).username + "\n"
//            }
//            console.log(data)
//        })

//    }
}
