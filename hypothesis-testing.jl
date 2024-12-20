module HypothesisTesting

using GenieFramework
using CSV
using PlotlyBase
using DataFrames
using PointProcessTools
import PointProcessTools: get_xs, get_ys
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
    @out p_val = 0.0
    @out params = ""
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

    @onchange rec, proxy, model_input begin
        show_plot = false
        if !(model_input == "" || isempty(rec.events))
            model = models[model_input]
            if model in ["ip", "ih"] && get_ys(proxy)[1] != -1
                results = fit_test(model, "lp", rec, proxy)
                cif = CIF(results.params, rec, proxy)
                xs = LinRange(rec.start, rec.finish, 1000)
            elseif model in ["hp", "hh"]
                results = fit_test(model, "lp", rec)
                cif = CIF(results.params, rec)
                xs = LinRange(rec.start, rec.finish, 1000)
            end

            cif_trace = scatter(x=xs, y=cif(xs),
                                mode="line", name="CIF")
            rec_trace = scatter(x=rec.events, y=fill(0.8 * minimum(cif), length(rec)),
                                mode="markers", name="events", marker_symbol=142, )
            plot_data = [cif_trace, rec_trace]
            layout = PlotlyBase.Layout(title="test")
            p_val = results.p
            params = string(results.params)
            show_plot = true
        end
    end
end

function ui()
    [
        row([h1("Hypothesis testing")]),
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
        row([p("p-value: {{p_val}}") ], @showif("show_plot")),
        row([p("Estimated parameters: {{params}}")], @showif("show_plot"))
    ]
end

@page("/hypothesis-testing", ui)
end
