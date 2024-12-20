module FrequencyAnalysis

using GenieFramework
using CSV
using PlotlyBase
using DataFrames
using PointProcessTools
@genietools

const model_keys = ["",
                    "Constant (Homogeneous Poisson)",
                    "Proxy dependent (Inhomogeneous Poisson)",
                    "Clustering (Homogeneous Hawkes)",
                    "Clustering + proxy (Inhomogneous Hawkes)"]

const model_values = ["",
                      "hp",
                      "ip",
                      "hh",
                      "ih"]

const models = Dict(model_keys .=> model_values)

@app begin
    @in model_input = ""
    @out show_plot = false
    @private rec = Record(Float64[], 0, 0)
    @private proxy = Proxy([0, 1], [-1, -1], normalize=false)
    @out plot_data = [scatter(x=[0], y=[0])]
    @out results = DataTable(DataFrame())
    # @out layout = PlotlyBase.Layout(title="test")

    @event rec_rejected begin
        notify(__model__, "Not a valid event record file.")
    end
    @event proxy_rejected begin
        notify(__model__, "Not a valid proxy file.")
    end

    @event rec_uploaded begin
        rec = Record(fileuploads["path"])
    end
    @event proxy_uploaded begin
        proxy = Proxy(fileuploads["path"])
    end

    @onchange rec begin
        show_plot = false
        if !isempty(rec.events)
            results_df = periodicities(rec)
            rec_trace = stem(x=1:length(results_df.Period), y=results_df.Power,
                             name="Data")
            plot_data = [rec_trace]
            layout = PlotlyBase.Layout(title="test")
            results = DataTable(results_df)
            show_plot = true
        end
        # if !(model_input == "" || isempty(rec.events))
        #     model = models[model_input]
        #     if model in ["ip", "ih"] && get_ys(proxy)[1] != -1
        #         results = periodicities(rec, proxy)
        #     elseif model in ["hp", "hh"]
        #         results = periodicities(rec)
        #     end
        #     rec_trace = stem(x=1:length(results.Period), y=results.Power,
        #                      name="Data")
        #     plot_data = [rec_trace]
        #     layout = PlotlyBase.Layout(title="test")
        #     show_plot = true
        # end
    end
end

function ui()
    [
        row([h1("Frequency Analysis")]),
        row([
            cell(class="col-md-6", [
                uploader(multiple=false,
                          accept=".csv",
                          maxfiles=1,
                          autoupload=true,
                          hideuploadbtn=true,
                          label="Upload event record",
                          @on("rejected", :rec_rejected),
                          @on("uploaded", :rec_uploaded)
                )
            ]),
            cell(class="col-md-6", [
                uploader(multiple=false,
                         accept=".csv",
                         maxfiles=1,
                         autoupload=true,
                         hideuploadbtn=true,
                         label="Upload proxy funciton (optional)",
                         @on("rejected", :proxy_rejected),
                         @on("uploaded", :proxy_uploaded)
                )]
            )
        ]),
    row([GenieFramework.select(:model_input,
                               options=model_keys,
                               label="Select model for the intensity of the process", 
                               multiple=false,
                               hideselected=false)]),
        row([plot(:plot_data, layout=:layout)], @showif("show_plot")),
        row([GenieFramework.table(:results, flat=true, bordered=true, title="Periodicities")], @showif("show_plot"))
    ]
end

@page("/frequency-analysis", ui)
end

