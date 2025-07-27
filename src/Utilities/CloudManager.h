#ifndef CLOUDMANAGER_H
#define CLOUDMANAGER_H

#include <QObject>
#include <QNetworkInformation>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkProxy>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QUrl>
#include <QFile>
#include <QtCore/QLoggingCategory>
#include <QtCore/QtSystemDetection>
#include <QtQmlIntegration/QtQmlIntegration>
#if defined(Q_OS_ANDROID)
#include <QJniObject>
#include <QJniEnvironment>
#endif

#include "QmlObjectListModel.h"

Q_DECLARE_LOGGING_CATEGORY(CloudManagerLog)

class CloudManager;
class DatabaseManager;

class CloudManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CloudManager     (QObject *parent = nullptr);
    ~CloudManager    ();

    static CloudManager *instance();

    void init();

    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(QString emailAddress READ emailAddress WRITE setEmailAddress NOTIFY emailAddressChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QmlObjectListModel* fileModel READ fileModel NOTIFY fileModelChanged)
    Q_PROPERTY(QList<QVariant> fileList READ fileList NOTIFY fileListChanged)
    Q_PROPERTY(bool signedIn READ signedIn WRITE setSignedIn NOTIFY signedInChanged)
    Q_PROPERTY(QString signedId READ signedId WRITE setSignedId NOTIFY signedIdChanged)
    Q_PROPERTY(QString signedUserName READ signedUserName WRITE setSignedUserName NOTIFY signedUserNameChanged)
    Q_PROPERTY(double uploadProgressValue READ uploadProgressValue WRITE setUploadProgressValue NOTIFY uploadProgressValueChanged)
    Q_PROPERTY(QString messageString READ messageString WRITE setMessageString NOTIFY messageStringChanged)
    Q_PROPERTY(QList<QVariant> dnEntryPlanFile READ dnEntryPlanFile NOTIFY dnEntryPlanFileChanged);
    Q_PROPERTY(double fileDownloadProgress READ fileDownloadProgress NOTIFY fileDownloadProgressChanged);

    Q_INVOKABLE void checkConnection();
    Q_INVOKABLE void signUserIn(const QString &emailAddress, const QString &password);
    Q_INVOKABLE void signUserOut();
    Q_INVOKABLE void loadDirFile(QString dirName);
    //Q_INVOKABLE void uploadFile(const QString &filePath, const QString &bucketName, const QString &objectName);
    Q_INVOKABLE void downloadObject(const QString &bucketName, const QString &objectName);
    Q_INVOKABLE void deleteObject(const QString &bucketName, const QString &objectName);
    Q_INVOKABLE void insertDataToDB(const QString &tableName, const QVariantMap &data);

    struct DownloadEntryFileInfo {
        QString key;
        QString lastModified;
        qint64 size;
        QString eTag;
    };

    void uploadJsonFile(const QJsonDocument &jsonDoc, const QString& bucketName, const QString& objectName);
    void getListBucket(const QString &bucketName);
    void setSignedIn (bool signedIn);
    void setSignedId (QString signedId);
    void setSignedUserName (QString signedUserName);
    void setMessageString (QString messageString);
    void setEmailAddress (QString email);
    void setPassword (QString password);
    void setUploadProgressValue(double progress);

    QmlObjectListModel* fileModel () { return & _uploadEntriesModel; }
    QList<QVariant> fileList() const { return m_fileList; }
    QList<QVariant> dnEntryPlanFile() const { return m_dnEntryPlanFile; }
    QString networkStatus() { return m_networkStatus; }
    QString emailAddress () { return _emailAddress; }
    QString password () { return _password; }
    bool signedIn              () const{ return m_signedIn; }
    QString signedId           () const{ return m_signedId; }
    QString signedUserName     () const{ return m_signedUserName; }
    QString messageString      () const{ return m_messageString; }
    double uploadProgressValue() const {return m_uploadProgressValue; }
    QList<DownloadEntryFileInfo> downloadEntryFileInfo() const { return m_downloadEntryFileInfo; }
    double fileDownloadProgress () const { return m_fileDownloadProgress; }

public slots:
    void networkReplyReadyRead();
    void signInReplyReadyRead();
    void networkReplyFinished();
    void networkReplyErrorOccurred(QNetworkReply::NetworkError code);
    void uploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onUploadFinished();
    void onDownloadFinished(QNetworkReply* reply, const QString& objectName);

signals:
    void fileListChanged();
    void fileModelChanged();
    void userSignIn();
    void signedInChanged();
    void signedIdChanged();
    void signedUserNameChanged();
    void messageStringChanged();
    void uploadProgressValueChanged();
    void dnEntryPlanFileChanged();
    void emailAddressChanged();
    void passwordChanged();
    void networkStatusChanged();
    void fileDownloadProgressChanged();

    void insertFlightLogSuccess();
    void insertFlightLogFailure(QString errorMessage);

    void connectionSuccess();
    void connectionFailed(QString message);

    void tokenRefreshed(const QString &newToken);
    void tokenRefreshFailed(const QString &error);

private:
    static const QString API_BASE_URL;
    static const QString SIGN_UP_ENDPOINT;
    static const QString SIGN_IN_ENDPOINT;
    static const QString USER_INFO_ENDPOINT;

    static constexpr const char* kCloudManagerGroup = "CloudManagerGroup";
    static constexpr const char* kEmailAddress      = "Email";
    static constexpr const char* kPassword          = "Password";

    QNetworkInformation *m_networkInfo = nullptr;
    QNetworkAccessManager *_nam;
    QNetworkReply *m_networkReply;
    QNetworkRequest m_networkRequest;
    QString databaseUrl;
    QString m_networkStatus;
    QString _emailAddress;
    QString _password;
    static const QString m_apiAnonKey;
    QString m_accessToken;
    QString m_refreshToken;
    QString m_signedUserName;
    QString m_localId;
    QString m_signedCompany;
    QString m_signedNickName;
    bool m_signedIn = false;
    QString m_signedId = "";
    QString m_messageString;
    static const QString m_endPointHost;
    QString formatFileSize(qint64 bytes);
    QmlObjectListModel _uploadEntriesModel;
    QList<QVariant> m_fileList;
    QString m_uploadId;
    QList<QString> m_partETags;
    int m_currentPart;
    QSharedPointer<QFile> m_file;
    QFile* _file;
    QByteArray getSignatureKey(const QByteArray &key, const QByteArray &dateStamp, const QByteArray &regionName, const QByteArray &serviceName);
    QString getAuthorizationHeader(const QString &httpVerb, const QString &canonicalUri, const QString &canonicalQueryString, const QString &payloadHash);
    double m_uploadProgressValue = 0.0;
    QString generateAuthorizationHeader(const QString &accessKey, const QString &secretKey, const QString &bucketName);
    QList<DownloadEntryFileInfo> m_downloadEntryFileInfo;
    QList<QVariant> m_dnEntryPlanFile;
    double m_fileDownloadProgress = 0.0;

    void requestSignIn(const QString & url, const QJsonDocument & payload );
    void sendGetRequest(const QString & databaseUrl);
    void parseResponse(const QByteArray & response );
    void handleError(const QJsonObject &errorObject);
    void initiateMultipartUpload(const QString &bucketName, const QString &objectName);
    void uploadPart(const QString &bucketName, const QString &objectName, int partNumber);
    void completeMultipartUpload(const QString &bucketName, const QString &objectName);
    void getPresignedUrl(const QString &bucketName, const QString &objectName, int expirationSeconds);
    void requestPresignedUrl(const QString &serverUrl, const QString &bucketName, const QString &objectName);
    void onRequestFinished();
    void parseJsonResponse(const QString &jsonResponse);
    void updateNetworkStatus();
    void downloadProgress(qint64 curr, qint64 total);
    void refreshAccessToken();
    bool isAccessTokenExpired(const QString &token);
#if defined(Q_OS_ANDROID)
    void installApkFromInternal(const QString &apkFilePath);
    void requestUnknownSourcePermission();
#endif

};

#endif // CLOUDMANAGER_H
