import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../componentes_dash/sidebar_menu.dart';
import '../componentes_dash/dashboard_colors.dart';

class ConfiguracoesScreen extends ConsumerStatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  ConsumerState<ConfiguracoesScreen> createState() =>
      _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends ConsumerState<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: isDark
          ? DashboardColors.backgroundDark
          : DashboardColors.backgroundLight,
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                selectedIndex: 4, // 'Configurações' is index 4
                onItemSelected: (index) {
                  if (index != 4) Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              selectedIndex: 4,
              onItemSelected: (index) {},
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark, isWideScreen),
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVisualTab(isDark),
                      _buildInfoTab(isDark),
                      _buildAddressTab(isDark),
                      _buildHoursTab(isDark),
                      _buildDeliveryTab(isDark),
                      _buildAdvancedTab(isDark),
                      _buildResponsibleTab(isDark),
                      _buildBankingTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? DashboardColors.backgroundDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isWideScreen)
                IconButton(
                  icon: Icon(Icons.menu,
                      color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurações da Loja',
                    style: GoogleFonts.publicSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isWideScreen)
                    Text(
                      'Gerencie todas as informações do seu estabelecimento',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alterações salvas com sucesso!')),
              );
            },
            icon: const Icon(Icons.save, size: 18),
            label: Text(isWideScreen ? 'Salvar Alterações' : 'Salvar',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? DashboardColors.backgroundDark : Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: DashboardColors.primary,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: DashboardColors.primary,
        indicatorWeight: 3,
        labelStyle:
            GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Visual', icon: Icon(Icons.palette, size: 18)),
          Tab(text: 'Info', icon: Icon(Icons.store, size: 18)),
          Tab(text: 'Endereço', icon: Icon(Icons.location_on, size: 18)),
          Tab(text: 'Horários', icon: Icon(Icons.schedule, size: 18)),
          Tab(text: 'Entrega', icon: Icon(Icons.local_shipping, size: 18)),
          Tab(text: 'Avançado', icon: Icon(Icons.tune, size: 18)),
          Tab(text: 'Responsável', icon: Icon(Icons.person, size: 18)),
          Tab(text: 'Bancários', icon: Icon(Icons.account_balance, size: 18)),
        ],
      ),
    );
  }

  // ============== TABS ==============

  Widget _buildVisualTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner & Logo
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                          child: Icon(Icons.photo_camera,
                              size: 48, color: Colors.grey)),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('Recomendado: 1200×400px',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color:
                                    isDark ? Colors.grey[900]! : Colors.white,
                                width: 4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child:
                              const Center(child: Icon(Icons.store, size: 40)),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logo e Banner',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Logo: mín. 200×200px. Banner: mín. 1200×400px. Formatos: JPG, PNG, WebP.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Remover Logo'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardColors.primary,
                                foregroundColor: Colors.white),
                            child: const Text('Alterar Logo'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fotos do Estabelecimento
          _buildSectionCard(
              title: 'Fotos do Estabelecimento',
              icon: Icons.photo_library,
              subtitle:
                  'Adicione até 8 fotos para mostrar seu espaço e produtos.',
              isDark: isDark,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildAddPhotoPlaceholder(isDark),
                    _buildPhotoItem(isDark, Icons.bakery_dining, Colors.orange),
                    _buildPhotoItem(isDark, Icons.coffee, Colors.brown),
                    _buildAddPhotoPlaceholder(isDark),
                  ],
                )
              ])
        ],
      ),
    );
  }

  Widget _buildPhotoItem(bool isDark, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  Widget _buildAddPhotoPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate,
              color: isDark ? Colors.grey[500] : Colors.grey[400]),
          const SizedBox(height: 4),
          Text('Adicionar',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Dados Públicos',
            icon: Icons.storefront,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Nome Fantasia *', 'Ex: Padoca Express', isDark,
                          helperText: 'Campo: nome_fantasia')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Slug (URL) *', 'padoca-express', isDark,
                          prefix: const Text('padoca.app/'),
                          helperText: 'Campo: slug')),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                  'Categoria do Estabelecimento',
                  ['🥐 Padaria e Confeitaria', '🍕 Pizzaria', '🍔 Lanchonete'],
                  isDark),
              const SizedBox(height: 16),
              _buildTextField('Tags', 'Ex: pão, café, orgânico', isDark,
                  helperText: 'Separe por vírgula'),
              const SizedBox(height: 16),
              _buildTextField('Descrição', 'Breve descrição...', isDark,
                  maxLines: 3),
            ],
          ),
          _buildSectionCard(
            title: 'Contato Comercial',
            icon: Icons.contacts,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Telefone Comercial', '(86) 3232-0000', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'WhatsApp', '(86) 99999-0000', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  'E-mail Comercial', 'contato@padocaexpress.com.br', isDark),
            ],
          ),
          _buildSectionCard(
            title: 'Dados Jurídicos',
            icon: Icons.business,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Razão Social', 'Padoca Express LTDA', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'CNPJ', '00.000.000/0001-00', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Inscrição Estadual', 'Opcional', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Inscrição Municipal', 'Opcional', isDark)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Endereço do Estabelecimento',
            icon: Icons.location_on,
            subtitle: 'Campos armazenados no objeto endereço (jsonb)',
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 1,
                      child: _buildTextField('CEP *', '64000-000', isDark,
                          suffix: const Icon(Icons.search,
                              color: DashboardColors.primary))),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 2,
                      child: _buildTextField(
                          'Logradouro *', 'Rua, Avenida...', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 1,
                      child: _buildTextField('Número *', '123', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: _buildTextField(
                          'Complemento', 'Sala, Loja...', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 2,
                      child: _buildTextField('Bairro *', 'Centro', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 2,
                      child: _buildTextField('Cidade *', 'Teresina', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: _buildDropdownField(
                          'Estado *', ['PI', 'SP', 'RJ', 'CE', 'MA'], isDark)),
                ],
              ),
            ],
          ),
          _buildSectionCard(
            title: 'Coordenadas Geográficas',
            icon: Icons.my_location,
            subtitle: 'Usadas para calcular distância e exibir no mapa.',
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField('Latitude', '-5.0892', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField('Longitude', '-42.8019', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: DashboardColors.primary),
                      SizedBox(height: 8),
                      Text('Mapa será exibido após inserir coordenadas')
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoursTab(bool isDark) {
    const days = [
      {'name': 'Segunda-feira', 'open': true},
      {'name': 'Terça-feira', 'open': true},
      {'name': 'Quarta-feira', 'open': true},
      {'name': 'Quinta-feira', 'open': true},
      {'name': 'Sexta-feira', 'open': true},
      {'name': 'Sábado', 'open': true},
      {'name': 'Domingo', 'open': false},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Horário de Funcionamento',
            icon: Icons.schedule,
            trailing: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar Seg-Sex')),
            isDark: isDark,
            children: days.map((day) {
              bool isOpen = day['open'] as bool;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color:
                              isDark ? Colors.grey[800]! : Colors.grey[100]!)),
                  color: isOpen
                      ? Colors.transparent
                      : (isDark ? Colors.black12 : Colors.grey[50]),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          Switch(
                              value: isOpen,
                              onChanged: (v) {},
                              activeColor: DashboardColors.primary),
                          const SizedBox(width: 8),
                          Text(day['name'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? null : Colors.grey))
                        ],
                      ),
                    ),
                    if (isOpen) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                          width: 100,
                          child: _buildTextField('', '06:00', isDark)),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('até',
                              style: TextStyle(color: Colors.grey))),
                      SizedBox(
                          width: 100,
                          child: _buildTextField('', '20:00', isDark)),
                    ] else ...[
                      const SizedBox(width: 32),
                      const Text('Fechado',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              );
            }).toList(),
          ),
          _buildSectionCard(
              title: 'Tempo Médio de Entrega',
              icon: Icons.delivery_dining,
              isDark: isDark,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child:
                            _buildTextField('Tempo médio (min)', '40', isDark)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            'Tempo médio de preparo (min)', '30', isDark)),
                  ],
                ),
              ])
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Configurações de Entrega',
            icon: Icons.local_shipping,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Taxa de Entrega Fixa (R\$)', '5.00', isDark,
                          prefix: const Text('R\$ '))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Taxa por KM (R\$)', '2.00', isDark,
                          prefix: const Text('R\$ '))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Pedido Mínimo (R\$)', '15.00', isDark,
                          prefix: const Text('R\$ '))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Frete Grátis Acima de (R\$)', '50.00', isDark,
                          prefix: const Text('R\$ '),
                          helperText: 'deixe 0 para desativar')),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raio Máximo de Entrega (km)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                            value: 8,
                            min: 1,
                            max: 30,
                            activeColor: DashboardColors.primary,
                            onChanged: (v) {}),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: DashboardColors.primary,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('8 km',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: DashboardColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: DashboardColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Resumo das Taxas de Entrega',
                        style: TextStyle(
                            color: DashboardColors.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSummaryCard('Taxa Fixa', 'R\$ 5,00', isDark),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Por KM', 'R\$ 2,00', isDark),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Grátis Acima', 'R\$ 50,00', isDark),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Raio Máximo', '8 km', isDark),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Configurações Avançadas',
            icon: Icons.tune,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Tempo Mínimo de Entrega (min)', '15', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          'Tempo Máximo de Entrega (min)', '60', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  'Intervalo de Atualização de Estoque (min)', '5', isDark),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aceita Agendamento',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Permite que clientes façam pedidos agendados.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: DashboardColors.primary)
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.05),
                  border: Border.all(
                      color: DashboardColors.primary.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTextField(
                    'Antecedência Mínima para Agendamento (min)', '60', isDark),
              )
            ],
          ),
          _buildSectionCard(
              title: 'Zona de Atenção',
              icon: Icons.warning,
              isDark: isDark,
              backgroundColor:
                  isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red[50],
              borderColor:
                  isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red[100],
              headerIconColor: Colors.red[600],
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Desativar Loja Temporariamente',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600])),
                        const SizedBox(height: 4),
                        Text(
                            'Sua loja ficará invisível no marketplace enquanto desativada.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red[400])),
                      ],
                    ),
                    OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Desativar Loja'))
                  ],
                ),
              ])
        ],
      ),
    );
  }

  Widget _buildResponsibleTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Dados do Responsável Legal',
            icon: Icons.person,
            subtitle:
                'Informações do responsável pela conta. Esses dados são confidenciais.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text('Dados sensíveis',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Nome Completo *', 'Nome do responsável', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child:
                          _buildTextField('CPF *', '000.000.000-00', isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Alterações nos dados do responsável podem requerer revalidação dos documentos. Em caso de dúvida, entre em contato com o suporte.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 13),
                    ))
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBankingTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Dados Bancários',
            icon: Icons.account_balance,
            subtitle: 'Conta para recebimento dos pagamentos.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Dados protegidos',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            isDark: isDark,
            children: [
              const Text('Tipo de Conta',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DashboardColors.primary)),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked,
                            color: DashboardColors.primary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Conta Corrente',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Pessoa Jurídica ou Física',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ],
                        )
                      ],
                    ),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!)),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked,
                            color: Colors.grey),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Conta Poupança',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Pessoa Física',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ],
                        )
                      ],
                    ),
                  ))
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                  'Banco *',
                  [
                    '001 - Banco do Brasil',
                    '104 - Caixa Econômica',
                    '341 - Itaú',
                    '260 - Nubank'
                  ],
                  isDark),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 1,
                      child: _buildTextField('Agência *', '0000', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  'Conta *', '00000000', isDark)),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 80,
                              child: _buildTextField('Dígito', '0', isDark)),
                        ],
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildTextField(
                          'Nome do Titular *', 'Como no banco', isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField('CPF/CNPJ do Titular *',
                          '00.000.000/0001-00', isDark)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Os dados bancários são criptografados e usados exclusivamente para repasse dos valores das vendas via Asaas. Alterações podem levar até 2 dias úteis para ser validadas.',
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ))
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // ============== HELPER BUILDERS ==============

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    required List<Widget> children,
    required bool isDark,
    Color? headerIconColor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.grey[900] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ?? (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            color: headerIconColor ?? DashboardColors.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder, bool isDark,
      {int maxLines = 1, Widget? prefix, Widget? suffix, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: DashboardColors.primary, width: 2),
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [prefix]))
                : null,
            suffixIcon: suffix,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
        ]
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.first,
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              onChanged: (String? newValue) {},
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
