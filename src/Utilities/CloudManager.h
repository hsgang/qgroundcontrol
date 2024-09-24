#ifndef CLOUDMANAGER_H
#define CLOUDMANAGER_H

#include "QGCToolbox.h"
#include "QGCApplication.h"

#include <QObject>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkProxy>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QUrl>
#include <QFile>

#include "QmlObjectListModel.h"

class CloudManager;

class CloudManager : public QGCTool
{
    Q_OBJECT
public:
    CloudManager     (QGCApplication* app, QGCToolbox* toolbox);
    ~CloudManager    ();

    Q_PROPERTY(QString emailAddress READ emailAddress WRITE setEmailAddress NOTIFY emailAddressChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QmlObjectListModel* fileModel READ fileModel NOTIFY fileModelChanged)
    Q_PROPERTY(QList<QVariant> fileList READ fileList NOTIFY fileListChanged)
    Q_PROPERTY(bool signedIn READ signedIn WRITE setSignedIn NOTIFY signedInChanged)
    Q_PROPERTY(QString signedId READ signedId WRITE setSignedId NOTIFY signedIdChanged)
    Q_PROPERTY(double uploadProgressValue READ uploadProgressValue WRITE setUploadProgressValue NOTIFY uploadProgressValueChanged)
    Q_PROPERTY(QString messageString READ messageString WRITE setMessageString NOTIFY messageStringChanged)
    Q_PROPERTY(QList<QVariant> dnEntryPlanFile READ dnEntryPlanFile NOTIFY dnEntryPlanFileChanged)

    Q_INVOKABLE void signUserUp(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserIn(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserOut();
    Q_INVOKABLE void loadDirFile(QString dirName);
    Q_INVOKABLE void uploadFile(const QString & filePath, const QString& bucketName, const QString& objectName);
    Q_INVOKABLE void downloadObject(const QString& bucketName, const QString& objectName);
    Q_INVOKABLE void deleteObject(const QString& bucketName, const QString& objectName);

    void uploadJson(const QJsonDocument &jsonDoc, const QString& bucketName, const QString& objectName);
    void getListBucket(const QString &bucketName);

    QmlObjectListModel* fileModel () { return & _uploadEntriesModel; }
    QList<QVariant> fileList() const { return m_fileList; }
    QList<QVariant> dnEntryPlanFile() const { return m_dnEntryPlanFile; }

    void setAPIKey (const QString & apiKey);
    void setToolbox (QGCToolbox *toolbox);
    void setSignedIn (bool signedIn);
    void setSignedId (QString signedId);
    void setMessageString (QString messageString);

    QString emailAddress () { return _emailAddress; }
    QString password () { return _password; }

    void setEmailAddress (QString email);
    void setPassword (QString password);

    bool signedIn              () const{ return m_signedIn; }
    QString signedId           () const{ return m_signedId; }
    QString messageString      () const{ return m_messageString; }

    QString minioEndpoint      () const{ return m_minioEndpoint; }
    QString minioAccessKey     () const{ return m_minioAccessKey; }
    QString minioSecretKey     () const{ return m_minioSecretKey; }

    double uploadProgressValue() const {return m_uploadProgressValue; }
    void setUploadProgressValue(double progress);

    struct DownloadEntryFileInfo {
        QString key;
        QString lastModified;
        qint64 size;
        QString eTag;
    };

    QList<DownloadEntryFileInfo> downloadEntryFileInfo() const { return m_downloadEntryFileInfo; }

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

private:

    static const QString API_BASE_URL;
    static const QString SIGN_UP_ENDPOINT;
    static const QString SIGN_IN_ENDPOINT;
    static const QString USER_INFO_ENDPOINT;

    QNetworkAccessManager *m_networkAccessManager;
    QNetworkReply *m_networkReply;
    QNetworkRequest m_networkRequest;
    QString databaseUrl;

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

    void performPOST(const QString & url, const QJsonDocument & payload );
    void requestSignIn(const QString & url, const QJsonDocument & payload );
    void sendGetRequest(const QString & databaseUrl);
    void parseResponse(const QByteArray & response );
    void handleError(const QJsonObject &errorObject);

    QString formatFileSize(qint64 bytes);

    QmlObjectListModel _uploadEntriesModel;
    QList<QVariant> m_fileList;

    QString m_uploadId;
    QList<QString> m_partETags;
    int m_currentPart;
    QSharedPointer<QFile> m_file;
    QFile* _file;

    QNetworkAccessManager*  _nam;

    void initiateMultipartUpload(const QString &bucketName, const QString &objectName);
    void uploadPart(const QString &bucketName, const QString &objectName, int partNumber);
    void completeMultipartUpload(const QString &bucketName, const QString &objectName);

    QByteArray getSignatureKey(const QByteArray &key, const QByteArray &dateStamp, const QByteArray &regionName, const QByteArray &serviceName);
    QString getAuthorizationHeader(const QString &httpVerb, const QString &canonicalUri, const QString &canonicalQueryString, const QString &payloadHash);

    void getPresignedUrl(const QString &bucketName, const QString &objectName, int expirationSeconds);

    void requestPresignedUrl(const QString &serverUrl, const QString &bucketName, const QString &objectName);
    void onRequestFinished();

    double m_uploadProgressValue = 0.0;

    void checkFilesExistInMinio(QString dirName);

    QString generateAuthorizationHeader(const QString &accessKey, const QString &secretKey, const QString &bucketName);

    QList<DownloadEntryFileInfo> m_downloadEntryFileInfo;

    QList<QVariant> m_dnEntryPlanFile;

    void parseXmlResponse(const QString &xmlResponse);

    static constexpr const char* kCloudManagerGroup = "CloudManagerGroup";
    static constexpr const char* kEmailAddress      = "Email";
    static constexpr const char* kPassword          = "Password";
};

#endif // CLOUDMANAGER_H
