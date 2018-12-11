// as per https://github.com/hyperledger/composer/issues/1996

const express = require('express');
const jwt = require('jsonwebtoken');
const request = require('request-promise');

const app = express()
app.get('/get-token', async (req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Credentials', 'true');
    //generate a signed token
    var token = jwt.sign({ id:"id", sub: 'sub', username: "username" }, 'secret');
    try {
        //start the request with a cookie jar
        const j = request.jar()
        const restServerDomain = 'http://172.20.67.68:3000'
        await request({
            uri: restServerDomain + '/auth/jwt/callback',
            headers: { 'Authorization': 'Bearer ' + token },
            jar: j
        })
        const cookies = j.getCookies(restServerDomain)
        let accessToken
        cookies.forEach(c => c.key === "access_token" ? accessToken = c.value : null)
        const error = new Error('No access token found')
        if (!accessToken) throw error
        cookies.forEach(c => c.key === "connect.sid" ? connectSid = c.value : null)
        const error2 = new Error('No connectsid token found')
        if (!connectSid) throw error2
        cookies.forEach(c => c.key === "userId" ? userID = c.value : null)
        const error3 = new Error('No userId token found')
        if (!userID) throw error3
        //respond to clients with the token to use in subrequest to the rest server
        res.json({ access_token: accessToken, connect_sid: connectSid, userId: userID })
    } catch (e) {
        return next(e)
    }
})
app.listen(3002, (e) => {
    if (e) {
        return console.log(e)
    }
    console.log('Listening on 3002')
})
