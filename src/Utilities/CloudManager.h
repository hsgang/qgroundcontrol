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
#ifdef __mobile__
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
public:
    CloudManager     (QObject *parent = nullptr);
    ~CloudManager    ();

    static CloudManager *instance();
    static void registerQmlTypes();

    void init();

    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(QString emailAddress READ emailAddress WRITE setEmailAddress NOTIFY emailAddressChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QmlObjectListModel* fileModel READ fileModel NOTIFY fileModelChanged)
    Q_PROPERTY(QList<QVariant> fileList READ fileList NOTIFY fileListChanged)
    Q_PROPERTY(bool signedIn READ signedIn WRITE setSignedIn NOTIFY signedInChanged)
    Q_PROPERTY(QString signedId READ signedId WRITE setSignedId NOTIFY signedIdChanged)
    Q_PROPERTY(double uploadProgressValue READ uploadProgressValue WRITE setUploadProgressValue NOTIFY uploadProgressValueChanged)
    Q_PROPERTY(QString messageString READ messageString WRITE setMessageString NOTIFY messageStringChanged)
    Q_PROPERTY(QList<QVariant> dnEntryPlanFile READ dnEntryPlanFile NOTIFY dnEntryPlanFileChanged);
    Q_PROPERTY(double fileDownloadProgress READ fileDownloadProgress NOTIFY fileDownloadProgressChanged);

    Q_INVOKABLE void signUserUp(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserIn(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserOut();
    Q_INVOKABLE void loadDirFile(QString dirName);
    Q_INVOKABLE void uploadFile(const QString & filePath, const QString& bucketName, const QString& objectName);
    Q_INVOKABLE void downloadObject(const QString& bucketName, const QString& objectName);
    Q_INVOKABLE void deleteObject(const QString& bucketName, const QString& objectName);
    Q_INVOKABLE void downloadForNewVersion();
    Q_INVOKABLE void installNewVersion(QString /*remoteFile*/, QString localFile, QString errorMsg);

    struct DownloadEntryFileInfo {
        QString key;
        QString lastModified;
        qint64 size;
        QString eTag;
    };

    void uploadJson(const QJsonDocument &jsonDoc, const QString& bucketName, const QString& objectName);
    void getListBucket(const QString &bucketName);
    void sendToDb(const QString &measurement, const QMap<QString, QString> &tags, const QMap<QString, QVariant> &fields);
    void uploadTakeoffRecord(double latitude, double longitude, double altitude, double voltage);

    void setAPIKey (const QString & apiKey);
    void setSignedIn (bool signedIn);
    void setSignedId (QString signedId);
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
    QString messageString      () const{ return m_messageString; }
    QString minioEndpoint      () const{ return m_minioEndpoint; }
    QString minioAccessKey     () const{ return m_minioAccessKey; }
    QString minioSecretKey     () const{ return m_minioSecretKey; }
    QString endPoint           () const{ return m_endPoint; }
    double uploadProgressValue() const {return m_uploadProgressValue; }
    QList<DownloadEntryFileInfo> downloadEntryFileInfo() const { return m_downloadEntryFileInfo; }
    double fileDownloadProgress () const { return m_fileDownloadProgress; }

public slots:
    void networkReplyReadyRead();
    void signInReplyReadyRead();
    void getSignInfoReplyReadyRead();
    void getKeysInfoReplyReadyRead();
    void networkReplyFinished();
    void networkReplyErrorOccurred(QNetworkReply::NetworkError code);
    void performAuthenticatedDatabaseCall();
    void getKeysDatabaseCall();
    void uploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onUploadFinished();
    void onDownloadFinished(QNetworkReply* reply, const QString& objectName);
    void onDbReplyFinished(QNetworkReply* reply);
    void uploadTakeoffRecordReplyReadyRead();

signals:
    void fileListChanged();
    void fileModelChanged();
    void userSignIn();
    void signedInChanged();
    void signedIdChanged();
    void messageStringChanged();
    void uploadProgressValueChanged();
    void dnEntryPlanFileChanged();
    void emailAddressChanged();
    void passwordChanged();
    void networkStatusChanged();
    void fileDownloadProgressChanged();

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
    QString m_apiKey;
    QString m_idToken;
    QString m_localId;
    QString m_signedCompany;
    QString m_signedNickName;
    bool m_signedIn = false;
    QString m_signedId = "";
    QString m_messageString;
    QString m_minioEndpoint;
    QString m_minioAccessKey;
    QString m_minioSecretKey;
    QString m_endPoint;
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

    void performPOST(const QString & url, const QJsonDocument & payload );
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
    void checkFilesExistInMinio(QString dirName);
    void parseXmlResponse(const QString &xmlResponse);
    void updateNetworkStatus();
    void downloadProgress(qint64 curr, qint64 total);
#ifdef __mobile__
    void installApkFromInternal(const QString &apkFilePath);
    void requestUnknownSourcePermission();
#endif

};

#endif // CLOUDMANAGER_H
