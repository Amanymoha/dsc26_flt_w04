import '../domain/stop.dart';

/// Today's route for the demo app and the public tests. One address is a long
/// Arabic one, the kind that overflows a fixed-height row at large text sizes.
const List<Stop> sampleStops = [
  Stop(
    id: 's1',
    customerName: 'Mona Adel',
    address: '12 Shehab St, Mohandessin, Giza',
    phone: '+20 100 123 4567',
    codPiasters: 45000,
  ),
  Stop(
    id: 's2',
    customerName: 'Karim Fathy',
    address: 'Building 7, Street 9, Maadi, Cairo',
    phone: '+20 122 555 0199',
    codPiasters: 0,
    status: StopStatus.delivered,
  ),
  Stop(
    id: 's3',
    customerName: 'هالة عبد الرحمن',
    address: 'شقة ١٤، الدور السابع، عمارة ٢٣ أ، شارع الدكتور محمد مندور '
        'المتفرع من شارع عباس العقاد، المنطقة السادسة، مدينة نصر، القاهرة، '
        'بجوار صيدلية العزبي وأمام بنك مصر',
    phone: '+20 111 777 3030',
    codPiasters: 128050,
  ),
  Stop(
    id: 's4',
    customerName: 'Omar Samir',
    address: '3 Port Said St, Downtown, Cairo',
    phone: '+20 155 010 2020',
    codPiasters: 0,
    status: StopStatus.failed,
  ),
  Stop(
    id: 's5',
    customerName: 'Nadia Hussein',
    address: '45 El Horreya Rd, Sidi Gaber, Alexandria',
    phone: '+20 109 444 8080',
    codPiasters: 22500,
  ),
];
