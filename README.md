# ios-fw-testhelper

iOS端末外部からネットワークでiOSアプリにテストコマンドを送信できるようにするためのフレームワーク。

## リファレンス
### TestCommandLister
*-- (instancetype)initWithPort:(short)port*

> テストコマンドの受信ポート番号を指定する。


*-- (void)registCommand:(NSString \*)command callback:(void (^)(void))callback*

> テストコマンドとコールバックを登録する。
テストコマンドは文字列で、使用可能な文字は[a-zA-Z1-9]である。


*-- (void)startListening*

>テストコマンドの受信を開始する。
登録されたテストコマンドを受信するとコールバックをメインスレッドで呼び出す。

## テストコマンド送信
### telnetを使う

	$ telnet ipaddr port
	$ command
