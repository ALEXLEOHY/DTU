---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by alex.
--- DateTime: 2023/7/21 16:02
---
--require("uartmodule")
mqttc = nil
--重启时间
local reconnect = 3000
function initMqttConnect(mqtt_url, mqtt_port, mqtt_isssl, client_id, user_name, password, subscribe, subscribe_qos, publish, publish_qos)

    mqttc = mqtt.create(nil, mqtt_url, mqtt_port, mqtt_isssl) -- mqtt客户端创建

    mqttc:auth(client_id, user_name, password) -- mqtt三元组配置
    print(client_id, user_name, password)
    mqttc:keepalive(180) -- 默认值240s
    mqttc:autoreconn(true, 6000) -- 自动重连机制
    mqttc:on(function(mqtt_client, event, data, payload)
        -- 用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        -- mqtt成功完成鉴权后的消息
        if event == "conack" then
            gpio.set(30, 0)
            mqttconnect = true

            sys.publish("mqtt_conack")
            mqtt_client:subscribe(subscribe, subscribe_qos)
        elseif event == "recv" then
            -- 服务器下发的数据
            log.info("mqtt", "downlink", "topic", data, "payload",
                    payload)
            uartSend(payload)
            -- 这里继续加自定义的业务处理逻辑
        elseif event == "sent" then
            -- publish成功后的事件
            log.info("mqtt", "sent", "pkgid", data)
        elseif event == "disconnect" then
            gpio.set(30, 1)
            -- 还没联网
            mqttconnect = false
            --log.info("服务器断开了",reconnect,"毫秒后重连")
            --sys.wait(reconnect)
            --exponentialBack()
        end
    end)
    -- 发起连接之后，mqtt库会自动维护链接，若连接断开，默认会自动重连
    -- todo 解除屏蔽
    mqttc:connect()
    sys.waitUntil("mqtt_conack")
    log.info("mqtt连接成功")

end

function exponentialBack(reconnectSecond)
    if  reconnect > 50000 then
        pm.reboot()
    end
    reconnect = reconnect+10000

end