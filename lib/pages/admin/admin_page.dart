import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alembro/widgets/loading.dart';
import 'package:alembro/widgets/error.dart';
import 'package:alembro/widgets/gradientgreen.dart';
import 'package:alembro/models/user.dart';
import 'package:alembro/models/company.dart';
import 'user_controller.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  final _userController = UserController();
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _userController.checkConnectionAndLoadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _userController,
      builder: (context, child) {
        if (_userController.isLoading) {
          return const Scaffold(
            body: Loading(
              icon: Icons.admin_panel_settings,
              color: Colors.white,
            ),
          );
        }

        if (_userController.criticalError) {
          return ErrorScreen(
            onRetry: _userController.checkConnectionAndLoadData,
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: GradientGreen.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 40,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 35,
                      child: Stack(
                        children: [
                          if (Navigator.canPop(context))
                            const Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: BackButton(color: Colors.white),
                            ),
                          const Center(
                            child: Text(
                              "Administração",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Pesquisar usuário',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (q) => _userController.filterUsers(q),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ..._userController.filteredUsers.map(
                      (u) => _buildUserCard(u),
                    ),

                    GestureDetector(
                      onTap: () => _showDialogNewUser(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: GradientGreen.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Novo Usuário",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User u) {
    final bool isInactive = u.active == 'N';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isInactive ? Colors.grey.shade800 : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      // se for admin = verde, se não (user) = azul
                      u.userType.toLowerCase() == 'admin'
                          ? Colors.green.shade100
                          : Colors.blue.shade50,
                  child: Image.asset(
                    u.userType.toLowerCase() == 'admin'
                        ? 'assets/icons/adminicon.png'
                        : 'assets/icons/usericon.png',
                    width: 24,
                    height: 24,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nomenclature,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isInactive ? Colors.white70 : Colors.black,
                        ),
                      ),
                      Text(
                        "${u.userName} | ${'*' * 8}",
                        style: TextStyle(
                          color: isInactive ? Colors.white54 : Colors.black87,
                        ),
                      ),
                      Text(
                        "${Company.fromId(u.companyId).name} | Vendedor: ${u.sellerId}",
                        style: TextStyle(
                          color: isInactive ? Colors.white54 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isInactive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.grey.shade700,
                    size: 30,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            left: 8,
            child: Text(
              u.userId.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.edit, size: 18, color: Colors.grey[700]),
              onPressed: () => _showDialogEditUser(u),
            ),
          ),
        ],
      ),
    );
  }

  void _showToastSellerId(String message) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showDialogNewUser() {
    final TextEditingController companyIdController = TextEditingController();
    final TextEditingController userController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nomenclatureController =
        TextEditingController();
    final TextEditingController sellerIdController = TextEditingController();
    final TextEditingController deviceCreditController =
        TextEditingController();
    String userType = "user";
    bool visiblePassword = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Novo Usuário",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: companyIdController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Id Empresa",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: userController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Usuário",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: passwordController,
                                obscureText: !visiblePassword,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Senha",
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      visiblePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        visiblePassword = !visiblePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: nomenclatureController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "nomenclature",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: sellerIdController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Id Vendedor",
                                ),
                                onTap: () {
                                  _showToastSellerId(
                                    "Id = 0 não puxa nenhum cliente, Id = 1 puxa todos os clientes.",
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: deviceCreditController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Crédito para novos dispositivos",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => userType = "user",
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              userType == "user"
                                                  ? Colors.blue.shade100
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color:
                                                  userType == "user"
                                                      ? Colors.blue
                                                      : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "User",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    userType == "user"
                                                        ? Colors.blue
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => userType = "admin",
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              userType == "admin"
                                                  ? Colors.green.shade100
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color:
                                                  userType == "admin"
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Admin",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    userType == "admin"
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final companyIdStr = companyIdController.text.trim();
                            final userName = userController.text.trim();
                            final password = passwordController.text.trim();
                            final nomenclature = nomenclatureController.text.trim();
                            final sellerIdStr = sellerIdController.text.trim();
                            final deviceCreditStr = deviceCreditController.text.trim();

                            if (companyIdStr.isEmpty ||
                                userName.isEmpty ||
                                password.isEmpty ||
                                nomenclature.isEmpty ||
                                sellerIdStr.isEmpty ||
                                deviceCreditStr.isEmpty) {
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Todos os campos são obrigatórios!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; 
                            }

                            final body = {
                              "companyId": int.parse(companyIdStr),
                              "userName": userName,
                              "password": password,
                              "nomenclature": nomenclature,
                              "sellerId": int.parse(sellerIdStr),
                              "deviceCredit": int.parse(deviceCreditStr),
                              "userType": userType, 
                            };

                            final nextId =
                                _userController.allUsers.isNotEmpty
                                    ? _userController.allUsers
                                            .map((u) => u.userId)
                                            .reduce((a, b) => a > b ? a : b) +
                                        1
                                    : 1;

                            final newUser = User(
                              userId: nextId,
                              companyId: body["companyId"] as int,
                              userName: body["userName"] as String,
                              sellerId: body["sellerId"] as int,
                              deviceCredit:
                                  body["deviceCredit"] as int,
                              userType: body["userType"] as String,
                              nomenclature: body["nomenclature"] as String,
                            );

                            await _userController.addUser(
                              body: body,
                              newUser: newUser,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text("Salvar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDialogEditUser(User u) {
    final int registerNewDevice = u.deviceCredit;
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController sellerController = TextEditingController(
      text: u.sellerId.toString(),
    );
    final TextEditingController newDeviceController = TextEditingController(
      text: registerNewDevice.toString(),
    );
    bool visiblePassword = false;

    String userType =
        (u.userType.toLowerCase() == "admin") ? "admin" : "user";

    String active = (u.active?.trim().toUpperCase() == 'S') ? 'S' : 'N';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Editar Usuário",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    Text(
                      u.userId.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.nomenclature,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Company.fromId(u.companyId).name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: passwordController,
                                obscureText: !visiblePassword,
                                decoration: InputDecoration(
                                  labelText: "Nova Senha",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      visiblePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        visiblePassword = !visiblePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: sellerController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Vendedor",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onTap: () {
                                  _showToastSellerId(
                                    "Id = 0 não puxa nenhum cliente, Id = 1 puxa todos os clientes.",
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: newDeviceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Novo Dispositivo",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => userType = "user",
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              userType == "user"
                                                  ? Colors.blue.shade100
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color:
                                                  userType == "user"
                                                      ? Colors.blue
                                                      : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "User",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    userType == "user"
                                                        ? Colors.blue
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => userType = "admin",
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              userType == "admin"
                                                  ? Colors.green.shade100
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color:
                                                  userType == "admin"
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Admin",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    userType == "admin"
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => active = 'S',
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              active == 'S'
                                                  ? Colors.green.shade200
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "ATIVO",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  active == 'S'
                                                      ? Colors.green.shade800
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => active = 'N',
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              active == 'N'
                                                  ? Colors.red.shade200
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "INATIVO",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  active == 'N'
                                                      ? Colors.red.shade800
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final Map<String, dynamic> body = {};
                            if (passwordController.text.isNotEmpty) {
                              body['senha'] = passwordController.text;
                            }
                            if (sellerController.text !=
                                u.sellerId.toString()) {
                              body['sellerId'] = int.tryParse(
                                sellerController.text,
                              );
                            }
                            if (newDeviceController.text !=
                                u.deviceCredit.toString()) {
                              body['deviceCredit'] = int.tryParse(
                                newDeviceController.text,
                              );
                            }

                            body['userType'] = userType;
                            body['ativo'] = active;

                            if (body.isEmpty) {
                              Navigator.pop(context);
                              return;
                            }

                            await _userController.updateUser(
                              userId: u.userId,
                              body: body,
                              userType: userType,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text("Salvar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}