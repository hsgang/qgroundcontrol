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

    Q_PROPERTY(QmlObjectListModel* fileModel READ fileModel NOTIFY fileModelChanged)
    Q_PROPERTY(QList<QVariant> fileList READ fileList NOTIFY fileListChanged)
    Q_PROPERTY(bool signedIn READ signedIn WRITE setSignedIn NOTIFY signedInChanged)
    Q_PROPERTY(QString signedId READ signedId WRITE setSignedId NOTIFY signedIdChanged)
    Q_PROPERTY(double uploadProgressValue READ uploadProgressValue WRITE setUploadProgressValue NOTIFY uploadProgressValueChanged)
    Q_PROPERTY(QString messageString READ messageString WRITE setMessageString NOTIFY messageStringChanged)

    QmlObjectListModel* fileModel () { return & _uploadEntriesModel; }
    QList<QVariant> fileList() const { return m_fileList; }

    void setAPIKey (const QString & apiKey);
    void setToolbox (QGCToolbox *toolbox);
    void setSignedIn (bool signedIn);
    void setSignedId (QString signedId);
    void setMessageString (QString messageString);

    bool signedIn              () const{ return m_signedIn; }
    QString signedId           () const{ return m_signedId; }
    QString messageString      () const{ return m_messageString; }

    QString minioEndpoint      () const{ return m_minioEndpoint; }
    QString minioAccessKey     () const{ return m_minioAccessKey;}
    QString minioSecretKey     () const{ return m_minioSecretKey; }

    double uploadProgressValue() const {return m_uploadProgressValue; }
    void setUploadProgressValue(double progress);

    Q_INVOKABLE void signUserUp(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserIn(const QString & emailAddress, const QString & password);
    Q_INVOKABLE void signUserOut();
    Q_INVOKABLE void loadDirFile(QString dirName);

    Q_INVOKABLE void uploadFile(const QString & filePath, const QString& bucketName, const QString& objectName);

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

signals:
    void fileListChanged();
    void fileModelChanged();
    void userSignIn();
    void signedInChanged();
    void signedIdChanged();
    void messageStringChanged();
    void uploadProgressValueChanged();

private:

    static const QString API_BASE_URL;
    static const QString SIGN_UP_ENDPOINT;
    static const QString SIGN_IN_ENDPOINT;
    static const QString USER_INFO_ENDPOINT;

    QNetworkAccessManager *m_networkAccessManager;
    QNetworkReply *m_networkReply;
    QNetworkRequest m_networkRequest;
    QString databaseUrl;

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
};

#endif // CLOUDMANAGER_H
