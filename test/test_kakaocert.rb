# -*- coding: utf-8 -*-
require 'test/unit'
require 'date'
require 'linkhub'
require_relative '../lib/kakaocert.rb'

class BaseServiceTest < Test::Unit::TestCase
  LinkID = "TESTER"
  SecretKey = "SwWxqU+0TErBXy/9TVjIPEnI0VTUMMSQZtJf3Ed8q3I="

  ServiceID = "KAKAOCERT"
  AccessID = "020040000001"
  Scope = ["member","310","320","330"]

  KakaocertInstance = KakaocertService.instance(BaseServiceTest::LinkID, BaseServiceTest::SecretKey)

  def test_01getTimeCompare
    auth = Linkhub.instance(BaseServiceTest::LinkID, BaseServiceTest::SecretKey)
    expiration = auth.getSessionToken(BaseServiceTest::ServiceID,
      BaseServiceTest::AccessID, BaseServiceTest::Scope)['expiration']
    sessionExpireTime = DateTime.parse(expiration)

    serverTime = auth.getTime
    apiServerTime = DateTime.strptime(serverTime)

    puts sessionExpireTime.to_s + ' ' + apiServerTime.to_s
    puts "Session Expiration : " + (apiServerTime < sessionExpireTime).to_s
    assert_not_nil(expiration)
  end

  def test_02singleton
    base = KakaocertService.instance(BaseServiceTest::LinkID, BaseServiceTest::SecretKey)
    base2 = KakaocertService.instance(BaseServiceTest::LinkID, BaseServiceTest::SecretKey)
    assert_equal(base, base2, "Popbill Singleton Instance Failure")
  end

  def test_03requestCMS
    cmsInfo = {
      "BankCode" => '004',
      "CallCenterNum" => '1600-8536',
      "Expires_in" => 60,
      "ReceiverBirthDay" => '19900108',
      "ReceiverHP" => '01012341234',
      "ReceiverName" => '홍길동',
      "BankAccountName" => '예금주명',
      "BankAccountNum" => '9-4324-5**7-58',
      "ClientUserID" => 'clientUserID-0423-01',
      "SubClientID" => '020040000001',
      "TMSMessage" => 'TMSMessage0423',
      "TMSTitle" => 'TMSTitle 0423',
      "isAllowSimpleRegistYN" => false,
      "isVerifyNameYN" => true,
      "PayLoad" => 'Payload123',
    }

    response = BaseServiceTest::KakaocertInstance.requestCMS(
      BaseServiceTest::AccessID,
      cmsInfo,
    )

    puts response
  end

  def test_4getCMSResult
    receiptID = "020062214041000001"

    response = BaseServiceTest::KakaocertInstance.getCMSResult(
      BaseServiceTest::AccessID,
      receiptID,
    )
    puts response
    assert_not_nil(response)
  end

  def test_05requestESign
    cmsInfo = {
      "BankCode" => '004',
      "CallCenterNum" => '1600-8536',
      "Expires_in" => 60,
      "ReceiverBirthDay" => '19900108',
      "ReceiverHP" => '01012341234',
      "ReceiverName" => '홍길동',
      "SubClientID" => '020040000001',
      "TMSMessage" => 'TMSMessage0423',
      "TMSTitle" => 'TMSTitle 0423',
      "isAllowSimpleRegistYN" => false,
      "isVerifyNameYN" => true,
      "Token" => "token value",
      "PayLoad" => 'Payload123',
    }

    response = BaseServiceTest::KakaocertInstance.requestESign(
      BaseServiceTest::AccessID,
      cmsInfo,
    )

    puts response
  end

  def test_5getESignResult
    receiptID = "020062214084900001"

    response = BaseServiceTest::KakaocertInstance.getESignResult(
      BaseServiceTest::AccessID,
      receiptID,
    )
    puts response
    assert_not_nil(response)
  end

  def test_06requestVerifyAuth
    cmsInfo = {
      "BankCode" => '004',
      "CallCenterNum" => '1600-8536',
      "Expires_in" => 60,
      "ReceiverBirthDay" => '19900108',
      "ReceiverHP" => '0101122',
      "ReceiverName" => '홍길동',
      "SubClientID" => '020040000001',
      "TMSMessage" => 'TMSMessage0423',
      "TMSTitle" => 'TMSTitle 0423',
      "isAllowSimpleRegistYN" => false,
      "isVerifyNameYN" => false,
      "Token" => "token value",
      "PayLoad" => 'Payload123',
    }

    response = BaseServiceTest::KakaocertInstance.requestVerifyAuth(
      BaseServiceTest::AccessID,
      cmsInfo,
    )

    puts response
  end

  def test_7getVerifyAuth
    receiptID = "020062214152000001"

    response = BaseServiceTest::KakaocertInstance.getVerifyAuthResult(
      BaseServiceTest::AccessID,
      receiptID,
    )
    puts response
    assert_not_nil(response)
  end


end
