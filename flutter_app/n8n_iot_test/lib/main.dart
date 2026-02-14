import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NTHU IoT Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // 0: 儀表板, 1: AI 管家

  // 頁面切換邏輯
  final List<Widget> _pages = [
    const DashboardTab(),
    const AIChatTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 顯示當前選中的頁面
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '儀表板',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'AI 管家',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 頁面 1: 儀表板 (直接連 n8n API)
// ==========================================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // n8n網址
  final String n8nUrl = 'https://URL.ngrok-free.app/webhook/control-device';
  //NGROK URL每次不一樣 需更換
  bool _isAcOn = false;
  double _acTemp = 26.0;
  bool _isLightOn = false;
  bool _isLoading = false;

  // 呼叫 n8n API 函式 
  Future<void> sendCommand(String deviceId, String action, {double? temp}) async {
    setState(() => _isLoading = true);
    try {
      // 1. 準備符合資料庫欄位的 JSON
      final Map<String, dynamic> data = {
        "timestamp": DateTime.now().toIso8601String(),
        "device_id": deviceId,            // 對應 device_id
        "temperature": temp ?? _acTemp,   // 對應 temperature
        "sleep_status": "User_Active",    // 手動操作時，預設為「使用者活躍中」
        "action_taken": action,           // 對應 action_taken (例如 TURN_ON)
      };

      // 2. 發送請求
      final response = await http.post(
        Uri.parse(n8nUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('✅ $deviceId 操作成功'), duration: const Duration(milliseconds: 500)),
        );
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 連線失敗: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏠 家庭控制中心'),
        centerTitle: true,
        actions: [_isLoading ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : const SizedBox()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 環境資訊卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade800]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [Icon(Icons.thermostat, color: Colors.white, size: 30), Text("28°C", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text("室內溫度", style: TextStyle(color: Colors.white70))]),
                  Column(children: [Icon(Icons.water_drop, color: Colors.white, size: 30), Text("65%", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text("濕度", style: TextStyle(color: Colors.white70))]),
                  Column(children: [Icon(Icons.flash_on, color: Colors.white, size: 30), Text("離峰", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text("目前電價", style: TextStyle(color: Colors.white70))]),
                ],//未來變更為感測器所取得之資料
              ),
            ),
            const SizedBox(height: 30),
            
            const Text("設備控制", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 2. 冷氣控制卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.ac_unit, color: _isAcOn ? Colors.blue : Colors.grey, size: 30),
                          const SizedBox(width: 10),
                          const Text("主臥冷氣", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                        Switch(
                          value: _isAcOn,
                          onChanged: (val) {
                            setState(() => _isAcOn = val);
                            // 這裡傳送具體的 Device ID 和 動作指令
                            sendCommand("AC_Master_Bedroom", val ? "TURN_ON" : "TURN_OFF");
                          },
                        )
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_acTemp.toStringAsFixed(1)}°C", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: _acTemp,
                            min: 16, max: 30, divisions: 14,
                            onChanged: _isAcOn ? (val) => setState(() => _acTemp = val) : null,
                            // 這裡傳送設定溫度的動作
                            onChangeEnd: (val) => sendCommand("AC_Master_Bedroom", "SET_TEMP", temp: val),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 3. 電燈控制卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Icon(Icons.lightbulb, color: _isLightOn ? Colors.orange : Colors.grey, size: 30),
                title: const Text("客廳電燈", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(_isLightOn ? "已開啟" : "已關閉"),
                trailing: Switch(
                  value: _isLightOn,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() => _isLightOn = val);
                    // 這裡傳送電燈的 Device ID
                    sendCommand("Light_Living_Room", val ? "TURN_ON" : "TURN_OFF");
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 頁面 2: AI 管家 (連 Python Agent API)
// ==========================================
class AIChatTab extends StatefulWidget {
  const AIChatTab({super.key});

  @override
  State<AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<AIChatTab> {
  // 未來更換為完成的Langchain語言模型
  final String pythonAgentUrl = 'https://xxxx.ngrok-free.app/chat'; 

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "bot", "text": "您好！我是您的智慧管家。有什麼我可以幫您的嗎？您可以叫我幫忙開燈，或是查詢現在的電價喔！"}
  ];
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    
    final userText = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": userText});
      _isTyping = true;
      _controller.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(pythonAgentUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userText}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); 
        setState(() {
          _messages.add({"role": "bot", "text": data['reply']});
        });
      } else {
        setState(() {
          _messages.add({"role": "bot", "text": "❌ 系統錯誤: ${response.statusCode}"});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "❌ 無法連接到 AI Agent...請檢查 Python Server"});
      });
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤖 AI 智慧管家')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      _messages[index]['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: Text("Agent 正在思考並操作設備...", style: TextStyle(color: Colors.grey))),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "試著說：幫我把冷氣設成 25 度...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  iconSize: 30,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}