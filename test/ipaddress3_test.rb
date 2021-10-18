require 'test_helper'

class IPAddressTest < Minitest::Test

  def setup
    @valid_ipv4   = "172.16.10.1/24"
    @valid_ipv6   = "2001:db8::8:800:200c:417a/64"
    @valid_mapped = "::13.1.68.3"

    @invalid_ipv4   = "10.0.0.256"
    @invalid_ipv6   = ":1:2:3:4:5:6:7"
    @invalid_mapped = "::1:2.3.4"

    @valid_ipv4_uint32 = [4294967295, # 255.255.255.255
                          167772160,  # 10.0.0.0
                          3232235520, # 192.168.0.0
                          0]

    @valid_ipv6_uint32 = [42540766411282592856906245548098208122, # 2001:0db8:0000:0000:0008:0800:200c:417a
                          42545680458834377588178886921629466625,  # 2002:0000:0000:0000:0000:0000:0000:0001
                          ]

    @invalid_ipv4_uint32 = [4294967296, # 256.0.0.0
                          "A294967295", # Invalid uINT
                          -1]           # Invalid

    @invalid_ipv6_uint32 = [21267647932558653966460912964485513215, # ffff:ffff:ffff:ffff:ffff:ffff:ffff
                          340282366920938463463374607431768211456, # 1000:0000:0000:0000:0000:0000:0000:0000" overflowed
                          ]    


    @ipv4class   = IPAddress::IPv4
    @ipv6class   = IPAddress::IPv6
    @mappedclass = IPAddress::IPv6::Mapped

    @invalid_ipv4 = ["10.0.0.256",
                     "10.0.0.0.0",
                     "10.0.0",
                     "10.0",
                     "0127.010.010.010",
                     "055.055.055.055"]

    @valid_ipv4_range = ["10.0.0.1-254",
                         "10.0.1-254.0",
                         "10.1-254.0.0"]

    @method = Module.method("IPAddress")
  end

  def test_method_IPAddress

    assert_instance_of @ipv4class, @method.call(@valid_ipv4)
    assert_instance_of @ipv6class, @method.call(@valid_ipv6)
    assert_instance_of @mappedclass, @method.call(@valid_mapped)

    assert_raises(ArgumentError) {@method.call(@invalid_ipv4)}
    assert_raises(ArgumentError) {@method.call(@invalid_ipv6)}
    assert_raises(ArgumentError) {@method.call(@invalid_mapped)}

    assert_instance_of @ipv4class, @method.call(@valid_ipv4_uint32[0])
    assert_instance_of @ipv4class, @method.call(@valid_ipv4_uint32[1])
    assert_instance_of @ipv4class, @method.call(@valid_ipv4_uint32[2])
    assert_instance_of @ipv4class, @method.call(@valid_ipv4_uint32[3])

    assert_raises(ArgumentError) {@method.call(@invalid_ipv4_uint32[0])}
    assert_raises(ArgumentError) {@method.call(@invalid_ipv4_uint32[1])}
    assert_raises(ArgumentError) {@method.call(@invalid_ipv4_uint32[2])}

    assert_instance_of @ipv6class, @method.call(@valid_ipv6_uint32[0])
    assert_instance_of @ipv6class, @method.call(@valid_ipv6_uint32[1])

    assert_raises(ArgumentError) {@method.call(@invalid_ipv6_uint32[0])}
    assert_raises(ArgumentError) {@method.call(@invalid_ipv6_uint32[1])}

  end

  def test_module_method_valid?
    assert_equal true, IPAddress::valid?("0.0.0.5/20")
    assert_equal true, IPAddress::valid?("0.0.0.0/8")
    assert_equal false, IPAddress::valid?("800.754.1.1/13")
    assert_equal false, IPAddress::valid?("0xff/4")
    assert_equal false, IPAddress::valid?("0xff.0xff.0xff.0xfe/20")
    assert_equal false, IPAddress::valid?("037.05.05.01/8")
    assert_equal false, IPAddress::valid?("0127.0.0.01/16")
    assert_equal false, IPAddress::valid?("055.027.043.09/16")
    # four digits fails the three digits check
    assert_equal false, IPAddress::valid?("0255.0255.0255.01/20")
    assert_equal false, IPAddress::valid?("013.055.0255.0216/29")
    assert_equal false, IPAddress::valid?("013.055.025.021/29")
    assert_equal false, IPAddress::valid?("052.015.024.020/29")
    assert_equal true, IPAddress::valid?("10.0.0.0/24")
    assert_equal true, IPAddress::valid?("10.0.0.0/255.255.255.0")
    assert_equal false, IPAddress::valid?("10.0.0.0/64")
    assert_equal false, IPAddress::valid?("10.0.0.0/255.255.255.256")
    assert_equal true, IPAddress::valid?("::/0")
    assert_equal true, IPAddress::valid?("2002::1/128")
    assert_equal true, IPAddress::valid?("dead:beef:cafe:babe::/64")
    assert_equal false, IPAddress::valid?("2002::1/129")
  end

  def test_module_method_valid_ip?
    assert_equal true, IPAddress::valid?("10.0.0.1")
    assert_equal true, IPAddress::valid?("10.0.0.0")
    assert_equal true, IPAddress::valid?("2002::1")
    assert_equal true, IPAddress::valid?("dead:beef:cafe:babe::f0ad")
    assert_equal false, IPAddress::valid?("10.0.0.256")
    assert_equal false, IPAddress::valid?("10.0.0.0.0")
    assert_equal false, IPAddress::valid?("10.0.0")
    assert_equal false, IPAddress::valid?("10.0")
    assert_equal false, IPAddress::valid?("2002:::1")
    assert_equal false, IPAddress::valid?("2002:516:2:200")
  end

  def test_module_method_valid_ipv4_netmask?
    assert_equal true, IPAddress::valid_ipv4_netmask?("255.255.255.0")
    assert_equal false, IPAddress::valid_ipv4_netmask?("10.0.0.1")
  end

  def test_module_method_valid_ipv4_subnet?
    assert_equal true, IPAddress::valid_ipv4_subnet?("10.0.0.0/255.255.255.0")
    assert_equal true, IPAddress::valid_ipv4_subnet?("10.0.0.0/0")
    assert_equal true, IPAddress::valid_ipv4_subnet?("10.0.0.0/32")
    assert_equal false, IPAddress::valid_ipv4_subnet?("10.0.0.0/ABC")
    assert_equal false, IPAddress::valid_ipv4_subnet?("10.0.0.1")
    assert_equal false, IPAddress::valid_ipv4_subnet?("10.0.0.0/33")
    assert_equal false, IPAddress::valid_ipv4_subnet?("10.0.0.256/24")
    assert_equal false, IPAddress::valid_ipv4_subnet?("10.0.0.0/255.255.255.256")
  end

  def test_module_method_valid_ipv6_subnet?
    assert_equal true, IPAddress::valid_ipv6_subnet?("::/0")
    assert_equal true, IPAddress::valid_ipv6_subnet?("2002::1/128")
    assert_equal true, IPAddress::valid_ipv6_subnet?("dead:beef:cafe:babe::/64")
    assert_equal false, IPAddress::valid_ipv6_subnet?("2002::1/129")
  end
end


