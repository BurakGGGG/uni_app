import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteMissingDepartments() async {
  final firestore = FirebaseFirestore.instance;
  
  final missingIds = [
    'odtu_veterinerlik',
    'odtu_diş_hekimligi',
    'odtu_hukuk',
    'odtu_gastronomi_ve_mutfak_sanatlari',
    'odtu_tip',
    'odtu_ilk_ve_acil_yardim_paramedik',
    'hacettepe_bilgisayar_programciligi',
    'hacettepe_yazilim_muhendisligi',
    'hacettepe_veterinerlik',
    'itu_ilk_ve_acil_yardim_paramedik',
    'itu_gastronomi_ve_mutfak_sanatlari',
    'itu_hukuk',
    'itu_dis_hekimligi',
    'itu_veterinerlik',
    'itu_yazilim_muhendisligi',
    'itu_bilgisayar_programciligi',
    'itu_tip',
    'istanbul_uni_yazilim_muhendisligi',
    'istanbul_uni_gastronomi_ve_mutfak_sanatlari',
    'ankara_uni_ilk_ve_acil_yardim_paramedik',
    'ankara_uni_yazilim_muhendisligi',
    'gazi_veterinerlik',
    'gazi_ilk_ve_acil_yardim_paramedik',
    'gazi_yazilim_muhendisligi',
    'ege_ilk_ve_acil_yardim_paramedik',
    'ege_veterinerlik',
    'ege_hukuk',
    'ege_yazilim_muhendisligi',
    'dokuz_eylul_ilk_ve_acil_yardim_paramedik',
    'dokuz_eylul_dis_hekimligi',
    'dokuz_eylul_yazilim_muhendisligi',
    'dokuz_eylul_bilgisayar_programciligi',
    'yildiz_teknik_ilk_ve_acil_yardim_paramedik',
    'yildiz_teknik_tip',
    'yildiz_teknik_gastronomi_ve_mutfak_sanatlari',
    'yildiz_teknik_veterinerlik',
    'yildiz_teknik_hukuk',
    'yildiz_teknik_dis_hekimligi',
    'yildiz_teknik_yazilim_muhendisligi',
    'yildiz_teknik_bilgisayar_programciligi',
    'akdeniz_yazilim_muhendisligi',
    'akdeniz_veterinerlik',
    'alanya_ilk_ve_acil_yardim_paramedik',
    'alanya_veterinerlik',
    'alanya_hukuk',
    'anadolu_ilk_ve_acil_yardim_paramedik',
    'anadolu_tip',
    'anadolu_veterinerlik',
    'anadolu_yazilim_muhendisligi',
    'anadolu_dis_hekimligi',
    'ogu_hukuk',
    'ogu_veterinerlik',
    'estu_ilk_ve_acil_yardim_paramedik',
    'estu_gastronomi_ve_mutfak_sanatlari',
    'estu_hukuk',
    'estu_tip',
    'estu_veterinerlik',
    'estu_dis_hekimligi',
    'estu_yazilim_muhendisligi',
    'uludag_yazilim_muhendisligi',
    'btu_ilk_ve_acil_yardim_paramedik',
    'btu_tip',
    'btu_gastronomi_ve_mutfak_sanatlari',
    'btu_veterinerlik',
    'btu_hukuk',
    'btu_dis_hekimligi',
    'btu_yazilim_muhendisligi',
    'btu_bilgisayar_programciligi',
    'comu_hukuk',
    'comu_yazilim_muhendisligi',
    'comu_veterinerlik',
    'comu_dis_hekimligi',
    'cumhuriyet_ilk_ve_acil_yardim_paramedik',
    'cumhuriyet_gastronomi_ve_mutfak_sanatlari',
    'sivas_btu_ilk_ve_acil_yardim_paramedik',
    'sivas_btu_tip',
    'sivas_btu_gastronomi_ve_mutfak_sanatlari',
    'sivas_btu_veterinerlik',
    'sivas_btu_hukuk',
    'sivas_btu_dis_hekimligi',
    'sivas_btu_bilgisayar_programciligi',
    'ktu_ilk_ve_acil_yardim_paramedik',
    'ktu_veterinerlik',
    'trabzon_uni_bilgisayar_muhendisligi',
    'trabzon_uni_ilk_ve_acil_yardim_paramedik',
    'trabzon_uni_tip',
    'trabzon_uni_gastronomi_ve_mutfak_sanatlari',
    'trabzon_uni_veterinerlik',
    'trabzon_uni_elektrik-elektronik_muhendisligi',
    'trabzon_uni_dis_hekimligi',
    'trabzon_uni_yazilim_muhendisligi',
    'mersin_uni_veterinerlik',
    'mersin_uni_yazilim_muhendisligi',
    'tarsus_tip',
    'tarsus_gastronomi_ve_mutfak_sanatlari',
    'tarsus_veterinerlik',
    'tarsus_hukuk',
    'tarsus_dis_hekimligi',
    'tarsus_bilgisayar_programciligi',
    'marmara_yazilim_muhendisligi',
    'marmara_veterinerlik',
    'hacibayram_bilgisayar_muhendisligi',
    'hacibayram_tip',
    'hacibayram_gastronomi_ve_mutfak_sanatlari',
    'hacibayram_veterinerlik',
    'hacibayram_elektrik-elektronik_muhendisligi',
    'hacibayram_dis_hekimligi',
    'hacibayram_yazilim_muhendisligi',
    'hacibayram_bilgisayar_programciligi',
    'izmir_demokrasi_ilk_ve_acil_yardim_paramedik',
    'izmir_demokrasi_gastronomi_ve_mutfak_sanatlari',
    'izmir_demokrasi_veterinerlik',
    'izmir_demokrasi_yazilim_muhendisligi',
    'izmir_demokrasi_bilgisayar_programciligi',
    'izmir_katipcelebi_ilk_ve_acil_yardim_paramedik',
    'izmir_katipcelebi_gastronomi_ve_mutfak_sanatlari',
    'izmir_katipcelebi_veterinerlik',
    'izmir_katipcelebi_yazilim_muhendisligi',
    'izmir_katipcelebi_bilgisayar_programciligi',
    'aydin_ilk_ve_acil_yardim_paramedik',
    'aydin_veterinerlik',
    'aydin_tip',
    'gelisim_veterinerlik',
    'medipol_ilk_ve_acil_yardim_paramedik',
    'medipol_veterinerlik',
    'hitit_ilk_ve_acil_yardim_paramedik',
    'hitit_hukuk',
    'hitit_dis_hekimligi',
    'hitit_veterinerlik',
    'hitit_yazilim_muhendisligi',
    'hitit_bilgisayar_programciligi'
  ];

  print('Temizlik başlıyor... Toplam silinecek bölüm: ${missingIds.length}');
  
  var batch = firestore.batch();
  var count = 0;
  var batchCount = 0;
  
  for (final id in missingIds) {
    batch.delete(firestore.collection('departments').doc(id));
    count++;
    
    if (count % 100 == 0) {
      await batch.commit();
      batchCount++;
      print('Batch $batchCount gönderildi (100 belge silindi)');
      batch = firestore.batch();
    }
  }
  
  if (count % 100 != 0) {
    await batch.commit();
    print('Son batch gönderildi. Temizlik tamamlandı!');
  }
}
