# -*- coding: utf-8 -*-
require 'net/http'
require 'uri'
require 'json'
require 'date'
require "digest"
require "base64"
require 'zlib'
require 'stringio'
require 'linkhub'

# Kakaocert API BaseService class
class KakaocertService

  ServiceID_REAL = "KAKAOCERT"
  ServiceURL_REAL = "https://kakaocert-api.linkhub.co.kr"
  KAKAOCERT_APIVersion = "1.0"
  BOUNDARY = "==KAKAOCERT_RUBY_SDK=="

  attr_accessor :token_table, :scopes, :linkhub, :ipRestrictOnOff

  # Generate Linkhub Class Singleton Instance
  class << self
    def instance(linkID, secretKey)
      @instance ||= new
      @instance.token_table = {}
      @instance.linkhub = Linkhub.instance(linkID, secretKey)
      @instance.scopes = ["member","310","320","330"]
      @instance.ipRestrictOnOff = true

      return @instance
    end

    private :new
  end


  # add Service Scope array
  def addScope(scopeValue)
    @scopes.push(scopeValue)
  end

  def setIpRestrictOnOff(value)
    @ipRestrictOnOff = value
  end


  # Get Session Token by checking token-cached hash or token Request
  def getSession_Token(corpNum)
    targetToken = nil
    refresh = false

    # check already cached CorpNum's SessionToken
    if @token_table.key?(corpNum.to_sym)
      targetToken = @token_table[corpNum.to_sym]
    end

    if targetToken.nil?
      refresh = true
    else
      # Token's expireTime must use parse() because time format is hh:mm:ss.SSSZ
      expireTime = DateTime.parse(targetToken['expiration'])
      serverUTCTime = DateTime.strptime(@linkhub.getTime())
      refresh = expireTime < serverUTCTime
    end

    if refresh
      begin
        # getSessionToken from Linkhub
        targetToken = @linkhub.getSessionToken(ServiceID_REAL, corpNum, @scopes, @ipRestrictOnOff ? "" : "*")

      rescue LinkhubException => le
        raise KakaocertException.new(le.code, le.message)
      end
      # append token to cache hash
      @token_table[corpNum.to_sym] = targetToken
    end

    targetToken['session_token']
  end

  # end of getSession_Token

  def gzip_parse (target)
    sio = StringIO.new(target)
    gz = Zlib::GzipReader.new(sio)
    gz.read()
  end

  # Kakaocert API http Get Request Func
  def httpget(url, corpNum, userID = '')
    headers = {
        "x-pb-version" => KAKAOCERT_APIVersion,
        "Accept-Encoding" => "gzip,deflate",
    }

    if corpNum.to_s != ''
      headers["Authorization"] = "Bearer " + getSession_Token(corpNum)
    end

    if userID.to_s != ''
      headers["x-pb-userid"] = userID
    end

    uri = URI(ServiceURL_REAL + url)
    request = Net::HTTP.new(uri.host, 443)
    request.use_ssl = true

    Net::HTTP::Get.new(uri)

    res = request.get(uri.request_uri, headers)

    if res.code == "200"
      if res.header['Content-Encoding'].eql?('gzip')
        JSON.parse(gzip_parse(res.body))
      else
        JSON.parse(res.body)
      end
    else
      raise KakaocertException.new(JSON.parse(res.body)["code"],
                                 JSON.parse(res.body)["message"])
    end
  end

  #end of httpget

  # Request HTTP Post
  def httppost(url, corpNum, postData, action = '', userID = '', contentsType = '')

    headers = {
        "x-lh-version" => KAKAOCERT_APIVersion,
        "Accept-Encoding" => "gzip,deflate",
    }

    apiServerTime = @linkhub.getTime()

    hmacTarget = "POST\n"
    hmacTarget += Base64.strict_encode64(Digest::MD5.digest(postData)) + "\n"
    hmacTarget += apiServerTime + "\n"

    hmacTarget += KAKAOCERT_APIVersion + "\n"

    key = Base64.decode64(@linkhub._secretKey)

    data = hmacTarget
    digest = OpenSSL::Digest.new("sha1")
    hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, key, data))

    headers["x-kc-auth"] = @linkhub._linkID+' '+hmac
    headers["x-lh-date"] = apiServerTime

    if contentsType == ''
      headers["Content-Type"] = "application/json; charset=utf8"
    else
      headers["Content-Type"] = contentsType
    end

    headers["Authorization"] = "Bearer " + getSession_Token(corpNum)


    uri = URI(ServiceURL_REAL + url)

    https = Net::HTTP.new(uri.host, 443)
    https.use_ssl = true
    Net::HTTP::Post.new(uri)

    res = https.post(uri.request_uri, postData, headers)

    if res.code == "200"
      if res.header['Content-Encoding'].eql?('gzip')
        JSON.parse(gzip_parse(res.body))
      else
        JSON.parse(res.body)
      end
    else
      raise KakaocertException.new(JSON.parse(res.body)["code"],
                                 JSON.parse(res.body)["message"])
    end
  end

  #end of httppost

  def requestCMS(clientCode, cmsRequestInfo)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    httppost("/SignDirectDebit/Request", clientCode, cmsRequestInfo.to_json, "", "")["receiptId"]
  end

  def requestESign(clientCode, esignRequestInfo)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    httppost("/SignToken/Request", clientCode, esignRequestInfo.to_json, "", "")
  end

  def requestVerifyAuth(clientCode, verifyAuthRequestInfo)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    httppost("/SignIdentity/Request", clientCode, verifyAuthRequestInfo.to_json, "", "")["receiptId"]
  end

  def getCMSState(clientCode, receiptID)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    httpget("/SignDirectDebit/Status/#{receiptID}", clientCode, "")
  end

  def getVerifyAuthState(clientCode, receiptID)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    httpget("/SignIdentity/Status/#{receiptID}", clientCode, "")
  end

  def getESignState(clientCode, receiptID)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    uri = "/SignToken/Status/#{receiptID}"

    httpget(uri, clientCode, "")
  end

  def verifyCMS(clientCode, receiptID)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    httpget("/SignDirectDebit/Verify/#{receiptID}", clientCode, "")
  end

  def verifyAuth(clientCode, receiptID)
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    httpget("/SignIdentity/Verify/#{receiptID}", clientCode, "")
  end

  def verifyESign(clientCode, receiptID, signature = '')
    if clientCode.to_s == ''
      raise KakaocertException.new('-99999999', '이용기관코드가 입력되지 않았습니다.')
    end
    if receiptID.to_s == ''
      raise KakaocertException.new('-99999999', '접수아이디가 입력되지 않았습니다.')
    end

    uri = "/SignToken/Verify/#{receiptID}"

    if signature.to_s != ''
      uri += "/"+signature
    end

    httpget(uri, clientCode, "")
  end



end



# Kakaocert API Exception Handler class
class KakaocertException < StandardError
  attr_reader :code, :message

  def initialize(code, message)
    @code = code
    @message = message
  end
end
