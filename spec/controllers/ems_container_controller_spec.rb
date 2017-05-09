describe EmsContainerController do
  before(:each) do
    stub_user(:features => :all)
  end

  it "#new" do
    controller.instance_variable_set(:@breadcrumbs, [])
    get :new

    expect(response.status).to eq(200)
  end

  describe "#show" do
    before do
      session[:settings] = {:views => {}, :quadicons => {}}
      EvmSpecHelper.create_guid_miq_server_zone
      login_as FactoryGirl.create(:user)
      @container = FactoryGirl.create(:ems_kubernetes)
    end

    context "render" do
      subject { get :show, :params => { :id => @container.id } }
      render_views
      it do
        is_expected.to have_http_status 200
        is_expected.to render_template(:partial => 'ems_container/_show_dashboard')
      end

      it "renders topology view" do
        get :show, :params => { :id => @container.id, :display => 'topology' }
        expect(response.status).to eq(200)
        expect(response.body).to_not be_empty
        expect(response).to render_template('container_topology/show')
      end
    end

    context "render dashboard" do
      subject { get :show, :params => { :id => @container.id, :display => 'dashboard' } }
      render_views

      it 'never render template show' do
        is_expected.not_to render_template('shared/views/ems_common/show')
      end

      it 'never render listnav' do
        is_expected.not_to render_template(:partial => "layouts/listnav/_ems_container")
      end

      it 'uses its own template' do
        is_expected.to have_http_status 200
        is_expected.not_to render_template(:partial => "ems_container/show_dashboard")
      end
    end
  end

  describe "Hawkular Disabled/Enabled" do
    let(:zone) { FactoryGirl.build(:zone) }
    let!(:server) { EvmSpecHelper.local_miq_server(:zone => zone) }

    before do
      allow(controller).to receive(:check_privileges).and_return(true)
      allow(controller).to receive(:assert_privileges).and_return(true)
    end

    it "Creates a provider with only one endpoint if hawkular is disabled" do
      post :create, :params => {
        "button"                    => "add",
        "cred_type"                 => "hawkular",
        "name"                      => "openshift_no_hawkular",
        "emstype"                   => "openshift",
        "zone"                      => 'default',
        "default_security_protocol" => "ssl-without-validation",
        "default_hostname"          => "default_hostname",
        "default_api_port"          => "5000",
        "default_userid"            => "",
        "default_password"          => "",
        "default_verify"            => "",
        "provider_region"           => "",
        "default_security_protocol" => "ssl-with-validation",
        "metrics_selection"         => "hawkular_disabled"
      }
      expect(response.status).to eq(200)
      ems_openshift = ManageIQ::Providers::ContainerManager.first
      expect(ems_openshift.endpoints.count).to be(1)
      expect(ems_openshift.endpoints.first.role).to eq('default')
    end

    it "Creates a provider with two endpoints if hawkular is enabled" do
      post :create, :params => {
        "button"                     => "add",
        "cred_type"                  => "hawkular",
        "name"                       => "openshift_no_hawkular",
        "emstype"                    => "openshift",
        "zone"                       => 'default',
        "default_security_protocol"  => "ssl-without-validation",
        "default_hostname"           => "default_hostname",
        "default_api_port"           => "5000",
        "default_userid"             => "",
        "default_password"           => "",
        "default_verify"             => "",
        "provider_region"            => "",
        "default_security_protocol"  => "ssl-with-validation",
        "metrics_selection"          => "hawkular_enabled",
        "hawkular_security_protocol" => "ssl-without-validation",
        "hawkular_hostname"          => "hawkular_hostname",
        "hawkular_api_port"          => "443",
      }
      expect(response.status).to eq(200)
      ems_openshift = ManageIQ::Providers::ContainerManager.first
      expect(ems_openshift.endpoints.count).to be(2)
      expect(ems_openshift.endpoints.first.role).to eq('default')
      expect(ems_openshift.endpoints.second.role).to eq('hawkular')
    end
  end

  include_examples '#download_summary_pdf', :ems_kubernetes
end
