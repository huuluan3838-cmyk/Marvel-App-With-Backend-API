import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final bool isDark;
  const AdminDashboardScreen({super.key, this.isDark = false});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;
  final _titles = const ['Bài viết', 'Thông báo', 'Địa điểm'];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F6F4);
    final pages = [
      _AdminPostsPage(isDark: isDark),
      _AdminNotificationPage(isDark: isDark),
      _AdminPlacesPage(isDark: isDark),
    ];

    Future<void> logout() async {
      await AuthState().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen(isDark: isDark)),
        (_) => false,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        if (isCompact) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              foregroundColor: isDark ? Colors.white : AppColors.black,
              elevation: 2,
              title: Text(_titles[_index], style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w900)),
              actions: [IconButton(onPressed: logout, tooltip: 'Đăng xuất', icon: const Icon(Icons.logout_rounded))],
            ),
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  return const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.article_rounded), label: 'Bài viết'),
                  NavigationDestination(icon: Icon(Icons.notifications_active_rounded), label: 'Thông báo'),
                  NavigationDestination(icon: Icon(Icons.add_location_alt_rounded), label: 'Địa điểm'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          body: Row(
            children: [
              _AdminSideBar(selected: _index, onSelect: (i) => setState(() => _index = i), onLogout: logout),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(title: _titles[_index], isDark: isDark),
                    Expanded(child: IndexedStack(index: _index, children: pages)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSideBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const _AdminSideBar({required this.selected, required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.article_rounded, 'Quản lý bài viết'),
      (Icons.notifications_active_rounded, 'Gửi thông báo'),
      (Icons.add_location_alt_rounded, 'Tạo địa điểm'),
    ];
    return Container(
      width: 260,
      color: const Color(0xFF123D2A),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF123D2A))),
          SizedBox(width: 12),
          Expanded(child: Text('Marvel Admin', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 8),
        const Text('Khu vực quản trị riêng', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 30),
        ...List.generate(items.length, (i) {
          final active = selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(items[i].$1, color: active ? const Color(0xFF123D2A) : Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(child: Text(items[i].$2, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: active ? const Color(0xFF123D2A) : Colors.white, fontWeight: FontWeight.w800))),
                ]),
              ),
            ),
          );
        }),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          label: const Text('Đăng xuất', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), minimumSize: const Size(double.infinity, 48)),
        )
      ]),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  final bool isDark;
  const _AdminTopBar({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Row(children: [
        Text(title, style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.black)),
        const Spacer(),
        Chip(avatar: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18), label: Text(AuthState().username, style: const TextStyle(fontFamily: AppTextStyles.fontFamily))),
      ]),
    );
  }
}

class _AdminPost {
  final int id; final String title; final String author; final String category; final String status; final String date;
  _AdminPost({required this.id, required this.title, required this.author, required this.category, required this.status, required this.date});
  factory _AdminPost.fromJson(Map<String, dynamic> j) => _AdminPost(
    id: j['maBaiViet'] is int ? j['maBaiViet'] : int.tryParse(j['maBaiViet']?.toString() ?? '0') ?? 0,
    title: j['tieuDe']?.toString() ?? '', author: 'User ${j['maNguoiDung'] ?? ''}', category: j['theLoai']?.toString() ?? '',
    status: j['trangThai']?.toString() ?? 'Pending', date: (j['ngayDang']?.toString() ?? '').take(10),
  );
}

extension on String { String take(int n) => length <= n ? this : substring(0, n); }

class _AdminPostsPage extends StatefulWidget { final bool isDark; const _AdminPostsPage({required this.isDark}); @override State<_AdminPostsPage> createState()=>_AdminPostsPageState(); }
class _AdminPostsPageState extends State<_AdminPostsPage> {
  final List<_AdminPost> _posts=[]; bool _loading=false;
  @override void initState(){super.initState(); _fetch();}
  Future<void> _fetch() async { final token=AuthState().token; if(token==null)return; setState(()=>_loading=true); try{ final r=await http.get(ApiConfig.uri('BaiViet/admin'),headers:{'Authorization':'Bearer $token'}); if(r.statusCode==200){ final data=jsonDecode(r.body) as List; setState(()=>_posts..clear()..addAll(data.map((e)=>_AdminPost.fromJson(e)))); } else {_msg('Không tải được bài viết: ${r.statusCode}');}}catch(e){_msg('Lỗi tải bài viết: $e');}finally{if(mounted)setState(()=>_loading=false);} }
  Future<void> _approve(_AdminPost p) async { final token=AuthState().token; if(token==null)return; final r=await http.put(ApiConfig.uri('BaiViet/approve/${p.id}'),headers:{'Authorization':'Bearer $token'}); _msg(r.statusCode==200?'Đã duyệt bài viết':'Duyệt thất bại: ${r.statusCode}'); await _fetch(); }
  void _msg(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override Widget build(BuildContext context){ final pending=_posts.where((e)=>e.status=='Pending').length; final reported=_posts.where((e)=>e.status=='Reported').length; final stats=[_MiniStat('T?ng b?i','${_posts.length}',Icons.article_rounded,Colors.blue),_MiniStat('Ch? duy?t','$pending',Icons.pending_actions_rounded,Colors.orange),_MiniStat('B? b?o c?o','$reported',Icons.report_rounded,Colors.red)]; return _AdminPagePadding(child: LayoutBuilder(builder:(context,constraints){ final compact=constraints.maxWidth<430; return Column(children:[ compact?Column(children:stats.map((w)=>Padding(padding:const EdgeInsets.only(bottom:8),child:w)).toList()):Row(children:stats.map((w)=>Expanded(child:Padding(padding:const EdgeInsets.only(right:8),child:w))).toList()), const SizedBox(height:10), Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.separated(itemCount:_posts.length, separatorBuilder:(_,__)=>const SizedBox(height:10), itemBuilder:(_,i){final p=_posts[i]; return Card(child:ListTile(isThreeLine:true,contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:8),leading:CircleAvatar(child:Text('${p.id}')), title:Text(p.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontFamily:AppTextStyles.fontFamily,fontWeight:FontWeight.w800)), subtitle:Text('${p.author} ? ${p.category}\n${p.date} ? ${p.status}',maxLines:2,overflow:TextOverflow.ellipsis), trailing:p.status=='Approved'?const Icon(Icons.check_circle,color:Colors.green):IconButton(onPressed:()=>_approve(p), icon:const Icon(Icons.check,color:Colors.green),tooltip:'Duy?t')));}))]); })); }
}

class _MiniStat extends StatelessWidget{final String t,v;final IconData i;final Color c;const _MiniStat(this.t,this.v,this.i,this.c);@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:12),child:Row(children:[CircleAvatar(radius:16,backgroundColor:c.withOpacity(.12),child:Icon(i,color:c,size:18)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text(v,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,fontFamily:AppTextStyles.fontFamily)),Text(t,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontFamily:AppTextStyles.fontFamily,color:Colors.grey))]))])));}
class _AdminPagePadding extends StatelessWidget{final Widget child;const _AdminPagePadding({required this.child});@override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.all(MediaQuery.of(context).size.width<700?10:24),child:child);}

class _AdminNotificationPage extends StatefulWidget{final bool isDark;const _AdminNotificationPage({required this.isDark});@override State<_AdminNotificationPage> createState()=>_AdminNotificationPageState();}
class _AdminNotificationPageState extends State<_AdminNotificationPage>{
  final _title=TextEditingController();
  final _body=TextEditingController();
  bool _all=true,_sending=false;
  List<dynamic> _users = [];
  final Set<int> _selectedUserIds = {};
  bool _loadingUsers = false;

  @override void initState(){
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final users = await ExtendedApiService.getAdminNotifyUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usersError = e.toString();
          _loadingUsers = false;
        });
        _msg('Lỗi tải người dùng: $e');
      }
    }
  }

  String? _usersError;

  void _selectAll(bool? select) {
    setState(() {
      if (select == true) {
        for (var u in _users) {
          final id = u['maNguoiDung'];
          if (id is int) _selectedUserIds.add(id);
        }
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  @override void dispose(){_title.dispose();_body.dispose();super.dispose();}

  Future<void> _send()async{
    if(_title.text.trim().isEmpty||_body.text.trim().isEmpty)return _msg('Vui lòng nhập tiêu đề và nội dung');
    if(!_all && _selectedUserIds.isEmpty) return _msg('Vui lòng chọn ít nhất một người dùng');
    
    setState(()=>_sending=true);
    try{
      final rs=await ExtendedApiService.sendAdminNotification(
        title:_title.text.trim(),
        content:_body.text.trim(),
        sendAll:_all,
        userIds:_all ? const [] : _selectedUserIds.toList(),
      );
      _title.clear();
      _body.clear();
      if (!_all) setState(() => _selectedUserIds.clear());
      _msg('Đã gửi thông báo tới ${rs['sentCount']??0} người dùng');
    }catch(e){_msg('Gửi thất bại: $e');}
    finally{if(mounted)setState(()=>_sending=false);}
  }

  void _msg(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));

  @override Widget build(BuildContext context)=>_AdminPagePadding(child:ListView(children:[Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Thông báo cho người dùng',style:TextStyle(fontFamily:AppTextStyles.fontFamily,fontSize:20,fontWeight:FontWeight.w900)),
    const SizedBox(height:16),
    TextField(controller:_title,decoration:const InputDecoration(labelText:'Tiêu đề',border:OutlineInputBorder())),
    const SizedBox(height:12),
    TextField(controller:_body,minLines:5,maxLines:8,decoration:const InputDecoration(labelText:'Nội dung thông báo',border:OutlineInputBorder())),
    const SizedBox(height:8),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value:_all,
      onChanged:(v)=>setState(()=>_all=v),
      title:const Text('Gửi đến tất cả người dùng', style: TextStyle(fontWeight: FontWeight.w600)),
    ),
    
    if (!_all) ...[
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Chọn người dùng (${_selectedUserIds.length}/${_users.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (!_loadingUsers && _users.isNotEmpty)
            TextButton(
              onPressed: () => _selectAll(_selectedUserIds.length < _users.length),
              child: Text(_selectedUserIds.length < _users.length ? 'Chọn tất cả' : 'Bỏ chọn tất cả'),
            ),
        ],
      ),
      if (_loadingUsers)
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
      else if (_usersError != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [
            Text('Lỗi: $_usersError', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetchUsers, child: const Text('Thử lại')),
          ]),
        )
      else if (_users.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Không tìm thấy người dùng nào'))
      else
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            itemCount: _users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = _users[index];
              final userId = user['maNguoiDung'] as int? ?? 0;
              final isSelected = _selectedUserIds.contains(userId);
              return CheckboxListTile(
                value: isSelected,
                title: Text(user['hoTen'] ?? 'Không rõ tên', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedUserIds.add(userId);
                    } else {
                      _selectedUserIds.remove(userId);
                    }
                  });
                },
              );
            },
          ),
        ),
    ],

    const SizedBox(height:16),
    ElevatedButton.icon(
      onPressed:_sending?null:_send,
      icon:const Icon(Icons.send),
      label:Text(_sending?'Đang gửi...':'Gửi thông báo'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
    )
  ])))]));}



class _AdminPlacesPage extends StatefulWidget{final bool isDark;const _AdminPlacesPage({required this.isDark});@override State<_AdminPlacesPage> createState()=>_AdminPlacesPageState();}
class _AdminPlacesPageState extends State<_AdminPlacesPage>{final _name=TextEditingController(),_province=TextEditingController(),_desc=TextEditingController(),_lng=TextEditingController(),_lat=TextEditingController(),_image=TextEditingController(),_detail=TextEditingController(),_detailImage=TextEditingController();final List<Map<String,String?>> _details=[];bool _saving=false;@override void dispose(){for(final c in [_name,_province,_desc,_lng,_lat,_image,_detail,_detailImage]){c.dispose();}super.dispose();}void _addDetail(){if(_detail.text.trim().isEmpty)return;setState((){_details.add({'tenChiTiet':_detail.text.trim(),'hinhAnh':_detailImage.text.trim().isEmpty?null:_detailImage.text.trim()});_detail.clear();_detailImage.clear();});}Future<void> _save()async{final lng=double.tryParse(_lng.text.trim()),lat=double.tryParse(_lat.text.trim());if(_name.text.trim().isEmpty||_province.text.trim().isEmpty||lng==null||lat==null)return _msg('Vui lòng nhập tên, tỉnh/thành, kinh độ và vĩ độ hợp lệ');setState(()=>_saving=true);try{final rs=await ExtendedApiService.createAdminDiaDiem(tenDiaDiem:_name.text.trim(),tinhThanh:_province.text.trim(),moTa:_desc.text.trim(),kinhDo:lng,viDo:lat,hinhAnh:_image.text.trim().isEmpty?null:_image.text.trim(),chiTiets:_details);_msg('Đã tạo địa điểm #${rs['maDiaDiem']}');for(final c in [_name,_province,_desc,_lng,_lat,_image]){c.clear();}setState(()=>_details.clear());}catch(e){_msg('Tạo địa điểm thất bại: $e');}finally{if(mounted)setState(()=>_saving=false);}}void _msg(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));@override Widget build(BuildContext context)=>_AdminPagePadding(child:ListView(children:[Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tạo địa điểm mới hiển thị trên bản đồ',style:TextStyle(fontFamily:AppTextStyles.fontFamily,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Dùng để thêm địa điểm hấp dẫn/địa điểm du lịch cho khách hàng xem và định vị trên bản đồ.'),const SizedBox(height:16),Row(children:[Expanded(child:TextField(controller:_name,decoration:const InputDecoration(labelText:'Tên địa điểm',border:OutlineInputBorder()))),const SizedBox(width:12),Expanded(child:TextField(controller:_province,decoration:const InputDecoration(labelText:'Tỉnh/Thành',border:OutlineInputBorder())))]),const SizedBox(height:12),TextField(controller:_desc,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'Mô tả',border:OutlineInputBorder())),const SizedBox(height:12),Row(children:[Expanded(child:TextField(controller:_lng,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Kinh độ',border:OutlineInputBorder()))),const SizedBox(width:12),Expanded(child:TextField(controller:_lat,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Vĩ độ',border:OutlineInputBorder())))]),const SizedBox(height:12),TextField(controller:_image,decoration:const InputDecoration(labelText:'URL hình ảnh',border:OutlineInputBorder())),const Divider(height:32),const Text('Địa điểm hấp dẫn / chi tiết du lịch',style:TextStyle(fontWeight:FontWeight.w800,fontFamily:AppTextStyles.fontFamily)),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:_detail,decoration:const InputDecoration(labelText:'Tên điểm chi tiết',border:OutlineInputBorder()))),const SizedBox(width:12),Expanded(child:TextField(controller:_detailImage,decoration:const InputDecoration(labelText:'URL ảnh chi tiết',border:OutlineInputBorder()))),IconButton(onPressed:_addDetail,icon:const Icon(Icons.add_circle,color:AppColors.primary,size:34))]),..._details.asMap().entries.map((e)=>ListTile(leading:const Icon(Icons.place),title:Text(e.value['tenChiTiet']??''),subtitle:Text(e.value['hinhAnh']??''),trailing:IconButton(icon:const Icon(Icons.delete),onPressed:()=>setState(()=>_details.removeAt(e.key))))),const SizedBox(height:14),ElevatedButton.icon(onPressed:_saving?null:_save,icon:const Icon(Icons.save),label:Text(_saving?'Đang lưu...':'Tạo địa điểm'))])))]));}

