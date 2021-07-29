# wallet
```bash
cd wallet/

dfx start --background

dfx deploy

#创建基础代币ICST
#此时的用户就是ICST的操作者和拥有者
dfx canister call wallet mintToken '(record{decimal=4;logo=vec{1} ;name="ICST TEST";symbol="ICST";totalSupply=1000.0;transferFee=0.01;})'

#查看所有token
dfx canister call wallet tokenList

#查看 某个token 的details(ps ICST)
dfx canister call wallet tokenDetail ICST
#查看 当前用户钱包的token信息
dfx canister call wallet walletTokenList

#创建用户
dfx identity new alice

#分别注册用户
dfx identity use alice
dfx canister call wallet register '(record{walletName="alice";walletpass="123456"})'

#添加token(ICST默认已经添加)
dfx canister call wallet addToken ICST

#删除token
dfx canister call wallet delToken ICST

#send token
dfx canister call transfer ICST 接收者的ID value 密码


```
