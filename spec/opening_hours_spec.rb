# frozen_string_literal: true

RSpec.describe OpeningHours do
  after do
    Timecop.return
    I18n.locale = I18n.default_locale
  end

  before do
    I18n.locale = "en"

    Timecop.freeze(Time.parse("2019-01-21 18:53:35 +0200")) # a Monday
  end

  it "has a version number" do
    expect(OpeningHours::VERSION).not_to be nil
  end

  describe "#parse" do
    context "when opening hours without period (always)" do
      let!(:entity) do
        {
          "openingHoursSpecificationSet" =>
          [
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "always",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Monday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                },
                {
                  "dayOfWeek" => "Tuesday",
                  "allDay" => true
                },
                {
                  "dayOfWeek" => "Wednesday",
                  "opens" => "21:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            }
          ],
          "opening_hours_description_translations" => {
            "en" => "Winter is coming!",
            "de" => "Der Winter kommt!"
          }
        }
      end

      it "returns correct opening hours without period" do
        response = described_class.parse(entity)

        expect(response.first).not_to include("Valid from 01.01.2019 to 01.03.2019")
        expect(response.first).to include("Monday: 17:00 - 22:00")
        expect(response.first).to include("Tuesday: 24 hours opened")
        expect(response.first).to include("Wednesday: 21:00 - 22:00")
        expect(response.first).to include("Thursday: Closed")
      end
    end

    context "when no opening hours but opening hours description" do
      let!(:entity) do
        {
          "openingHoursSpecificationSet" => [],
          "opening_hours_description_translations" => {
            "en" => "Winter is coming!",
            "de" => "Der Winter kommt!"
          }
        }
      end

      it "returns opening hours description" do
        response = described_class.parse(entity)

        expect(response.first).to include("Winter is coming")
      end
    end

    context "when period is provided (from..to)" do
      let!(:entity) do
        {
          "openingHoursSpecificationSet" =>
          [
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "Whatever",
              "validFrom" => "2019-01-01",
              "validThrough" => "2019-03-01",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Monday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                },
                {
                  "dayOfWeek" => "Tuesday",
                  "allDay" => true
                },
                {
                  "dayOfWeek" => "Wednesday",
                  "opens" => "21:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            }
          ],
          "opening_hours_description_translations" => {
            "en" => "Winter is coming!",
            "de" => "Der Winter kommt!"
          }
        }
      end

      it "returns an array" do
        response = described_class.parse(entity)

        expect(response).to be_a(Array)
      end

      it "returns the opening hours text" do
        response = described_class.parse(entity)

        expect(response.first).not_to be_empty
        expect(response.first).to be_a(String)
      end

      it "returns correct opening hours" do
        response = described_class.parse(entity)

        expect(response.first).to include("Valid from 01.01.2019 to 01.03.2019")
        expect(response.first).to include("Monday: 17:00 - 22:00")
        expect(response.first).to include("Tuesday: 24 hours opened")
        expect(response.first).to include("Wednesday: 21:00 - 22:00")
        expect(response.first).to include("Thursday: Closed")

        expect(response[1]).to include("Winter is coming")
      end
    end

    context "when current date not included in any sets" do
      let!(:entity) do
        {
          "openingHoursSpecificationSet" => [
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "Whatever",
              "validFrom" => "2019-01-01",
              "validThrough" => "2019-01-20",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Monday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            },
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "Whatever 2",
              "validFrom" => "2019-04-01",
              "validThrough" => "2019-06-30",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Tuesday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            }
          ]
        }
      end

      it "returns the opening hours text" do
        response = described_class.parse(entity)

        expect(response.first).to eq(I18n.t("no_opening_hours_set"))
      end
    end

    context "when current date included in set" do
      let!(:entity) do
        {
          "openingHoursSpecificationSet" => [
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "Whatever",
              "validFrom" => "2019-01-01",
              "validThrough" => "2019-03-01",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Monday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            },
            {
              "@type" => "OpeningHoursSpecification",
              "name" => "Whatever 2",
              "validFrom" => "2019-04-01",
              "validThrough" => "2019-06-30",
              "openingHoursSpecification" => [
                {
                  "dayOfWeek" => "Tuesday",
                  "opens" => "17:00",
                  "closes" => "22:00",
                  "allDay" => false
                }
              ]
            }
          ]
        }
      end

      it "selects the right opening hours set" do
        response = described_class.parse(entity)

        expect(response.first).to include("Valid from 01.01.2019 to 01.03.2019")
      end
    end
  end
end
